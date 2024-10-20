import { writeFileSync } from "fs";

// notice for myself - Binaries for MongoDB tools can be fetched here:
// https://downloads.mongodb.org/tools/db/full.json

const versions = (await (
  await fetch("https://downloads.mongodb.org/full.json")
).json()) as {
  versions: Array<{
    version: string;
    date: string;
    downloads: Array<{
      arch: string;
      target: string;
      edition: "enterprise" | "base" | "targeted";
      archive: {
        url: string;
        sha256: string;
      };
    }>;
  }>;
};

type Release = {
  names: string[];
  openssl: "1.0" | "1.1" | "3.0";
  platforms: Platforms;
};

type Platforms = Record<string, Variant[]>;

type Variant = {
  url: string;
  sha256: string;
};

type Version = {
  major: number;
  minor: number;
  patch: number;
};

const architectures = ["x86_64", "arm64"];
const platforms = ["darwin", "linux"];

const compareVersion = (a: Version, b: Version) => {
  if (a.major !== b.major) return a.major - b.major;
  if (a.minor !== b.minor) return a.minor - b.minor;
  return a.patch - b.patch;
};

const isLatestMajor = (version: Version, allVersions: Version[]) => {
  const nextMajor: Version = {
    major: version.major + 1,
    minor: 0,
    patch: 0,
  };
  return !allVersions.find(
    (v) => compareVersion(v, version) > 0 && compareVersion(v, nextMajor) < 0
  );
};

const isLatestMinor = (version: Version, allVersions: Version[]) => {
  const nextMinor: Version = {
    major: version.major,
    minor: version.minor + 1,
    patch: 0,
  };
  return !allVersions.find(
    (v) => compareVersion(v, version) > 0 && compareVersion(v, nextMinor) < 0
  );
};

const preprocessedVersions = versions.versions
  .map((version) => version)
  .filter((version) => !version.version.includes("-"))
  .map((version) => {
    const [major, minor, patch] = version.version.split(".").map(parseFloat);
    return {
      ...version,
      major,
      minor,
      patch,
    };
  });

const releases: Release[] = preprocessedVersions
  .filter((version) => !version.version.includes("-"))
  .map((version) => {
    const date = new Date(version.date);
    const major = version.major;
    const minor = version.minor;
    const patch = version.patch;
    const latestMajor = isLatestMajor(version, preprocessedVersions);
    const latestMinor = isLatestMinor(version, preprocessedVersions);
    return {
      openssl:
        major > 6 || (major === 6 && (minor > 0 || patch > 3))
          ? "3.0"
          : major > 4 || (major === 4 && (minor > 0 || patch > 0))
          ? "1.1"
          : "1.0",
      names: [
        `${major}-${minor}-${patch}`,
        ...(latestMinor ? [`${major}-${minor}`] : []),
        ...(latestMajor ? [`${major}`] : []),
      ],
      platforms: Object.fromEntries(
        architectures.flatMap((arch) =>
          platforms.flatMap((platform) => {
            const variants = version.downloads.filter(
              (download) =>
                (arch === "x86_64"
                  ? arch === download.arch
                  : download.arch === "arm64" || download.arch === "aarch64") &&
                (platform === "darwin"
                  ? download.target === "macos"
                  : download.target.startsWith("ubuntu")) &&
                download.edition !== "enterprise"
            );
            if (!variants.length) return [];
            return [
              [
                `${arch}-${platform}`,
                variants
                  .toSorted((a, b) => b.target.localeCompare(a.target))
                  .map((download) => ({
                    url: download!.archive.url,
                    sha256: download!.archive.sha256,
                  }))
                  .slice(0, 1),
              ],
            ];
          })
        )
      ),
    };
  });

writeFileSync("./releases.json", JSON.stringify(releases, null, "\t"));
