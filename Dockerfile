FROM irreverentpixelfeats/idris-build:ubuntu_xenial_1.0-20170815083422-e277b06
MAINTAINER Dom De Re <domdere@irreverentpixelfeats.com>

ENV LANGUAGE_CIL_VERSION=0438ed5
ENV IDRIS_CIL_VERSION=00e977f
ENV IDRIS_DEV_VERSION=ea2041c

ADD tars /tmp

# idris-cil only builds with idris-1.0 atm and also needs
# an additional constraint to build a specific version of cheapskate
# this requires a little bit of hackery...
# I add language-cil as a git submodule
# so i can play around with the idea of building it with
# mafia in the future, but Idris-dev has complicated build that
# doesnt work so well with mafia atm.
# hence the submodule stuff isnt necessary right now,
# but doesnt hurt either so i left it in
RUN cd /opt \
  && git clone https://github.com/bamboo/idris-cil.git \
  && cd /opt/idris/idris-${IDRIS_VERSION} \
  && cp -v idris.cabal idris.cabal.bk \
  && (cat idris.cabal.bk | sed "s@\(^Version:.*\)1\.0.*@\199.0.0@" > idris.cabal) \
  && grep "^Version:" idris.cabal \
  && cd /opt/idris-cil \
  && git checkout ${IDRIS_CIL_VERSION} \
  && git checkout -b topic/irreverent-build \
  && mkdir -p lib \
  && cd lib \
  && git submodule add https://github.com/bamboo/language-cil.git \
  && cd language-cil \
  && git checkout ${LANGUAGE_CIL_VERSION} \
  && cp -v language-cil.cabal language-cil.cabal.bk \
  && (cat language-cil.cabal.bk | sed "s@\(^version:[ ]*\)[0-9].*@\199.0.0@" > language-cil.cabal) \
  && grep "^version:" language-cil.cabal \
  && cd ../../ \
  && git add -v lib \
  && git config --local "user.name" "foo" \
  && git config --local "user.email" "foo@foo.com" \
  && git commit -m "Adding submodules" \
  #&& cp -v /opt/idris/idris-${IDRIS_VERSION}/src/Target_idris.hs lib/Idris-dev/src/ \
  && cabal sandbox init \
  && cabal update \
  && cabal sandbox add-source /opt/idris/idris-${IDRIS_VERSION} \
  && cabal sandbox add-source lib/language-cil \
  && cp -v /tmp/idris-cil.cabal.config cabal.config \
  && cabal install --only-dependencies --reorder-goals --max-backjumps=-1 -j \
  && cd /opt/idris/idris-${IDRIS_VERSION} \
  && mv -v idris.cabal.bk idris.cabal \
  && cd /opt/idris-cil \
  && cabal configure \
  && cabal install -j \
  && ln -sf /opt/idris-cil/.cabal-sandbox/bin/idris-codegen-cil /usr/local/bin \
# Install the idris CIL FFI
  && cd /opt/idris-cil/rts \
  && idris --install cil.ipkg

# Mono
# http://www.mono-project.com/download/#download-lin
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
  && (echo "deb http://download.mono-project.com/repo/ubuntu xenial main" | tee /etc/apt/sources.list.d/mono-official.list) \
  && apt-get update \
  && apt-get install -y mono-devel=5.2.0.215-0xamarin10+ubuntu1604b1

# stuff in the data dir is likely to change very frequently but doesnt actually affect the image much itself,
# example: version SHAs
# So adding it last should speed up the builds
ADD data /tmp

# Add the git-sha for the docker file to the image so if you need you can see where
# your image sat in the timeline of git changes (which might be tricky to correlate with the
# docker hub changes)
RUN mkdir -p /var/versions && cp -v /tmp/version /var/versions/idris-cil-build-ubuntu_xenial-${IDRIS_VERSION}.version
