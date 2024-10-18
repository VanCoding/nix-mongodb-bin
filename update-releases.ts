import { writeFileSync } from "fs";

const versions = (await (
  await fetch("http://downloads.mongodb.org.s3.amazonaws.com/full.json")
).json()) as {
  versions: Array<{
    version: string;
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

type Releases = Record<string, Platforms>;

type Platforms = Record<string, Variant[]>;

type Variant = {
  url: string;
  sha256: string;
};

const architectures = ["x86_64", "arm64"];
const platforms = ["darwin", "linux"];

const releases: Releases = Object.fromEntries(
  versions.versions
    .filter((version) => !version.version.includes("-"))
    .map((version) => [
      version.version.replaceAll(".", "-"),
      Object.fromEntries(
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
    ])
);

writeFileSync("./releases.json", JSON.stringify(releases, null, "\t"));
