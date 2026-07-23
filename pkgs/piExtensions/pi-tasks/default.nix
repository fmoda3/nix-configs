{ buildPiExtension
, fetchFromGitHub
}:

buildPiExtension {
  pname = "pi-tasks";
  version = "2026-07-22";

  src = fetchFromGitHub {
    owner = "tintinweb";
    repo = "pi-tasks";
    rev = "03a13011eb7bfb63d6d348959fe738ab7365ea75";
    sha256 = "sha256-aKCJKkl1jmAQ17eJ6wmnu6cjhwY2t3PB0yIqyYgqQHY=";
  };

  postPatch = ''
    substituteInPlace package-lock.json \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.81.1.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-agent-core": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-agent-core/-/pi-agent-core-0.81.1.tgz",\n      "integrity": "sha512-yqbh68CyhqxMov/jUogFJfMqlu2Gd37GAki+tr59YCmAPHfomiCA5ESzusXtpGzABeiZFC/OrRdQ4GwCCOMIHA==",\n      "license": "MIT",' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.81.1.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-ai": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-ai/-/pi-ai-0.81.1.tgz",\n      "integrity": "sha512-hzHE7Z8l5mgJk+ke67Lge0rwS2+wbKJrFKl9o5M1R1rh33+cCT7D1AHz1OAtX5wFs90E1/BTGhyJRTUHaMxGvQ==",\n      "license": "MIT",' \
      --replace-fail $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.81.1.tgz",\n      "license": "MIT",' $'"node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui": {\n      "version": "0.81.1",\n      "resolved": "https://registry.npmjs.org/@earendil-works/pi-tui/-/pi-tui-0.81.1.tgz",\n      "integrity": "sha512-OMEe+Zt8oQYi/rCq3upxsTlIScWL0FPhXwQus34TbQb3EmTx88S7Uzx32JxvQiEeWOw8eDCdJf2PBUBE9r6wIg==",\n      "license": "MIT",'
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-t/sBkRjYSRRhMjKsCU5RvuGbIGRakBel5TAGX4xKAT0=";

  prunePaths = [
    ".github"
    "test"
    "media"
  ];
}
