import { writeFileSync } from "fs";

const versions = (await (
  await fetch("http://downloads.mongodb.org.s3.amazonaws.com/full.json")
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

type Releases = Record<string, Release>;

type Release = {
  openssl: "1.0" | "1.1" | "3.0";
  platforms: Platforms;
};

type Platforms = Record<string, Variant[]>;

type Variant = {
  url: string;
  sha256: string;
};

const architectures = ["x86_64", "arm64"];
const platforms = ["darwin", "linux"];

const SWITCH_TO_OPENSSL_3 = new Date("2022-01-01");
const SWITCH_TO_OPENSSL_1_1 = new Date("2018-08-01");

const releases: Releases = Object.fromEntries(
  versions.versions
    .filter((version) => !version.version.includes("-"))
    .map((version) => {
      const date = new Date(version.date);
      return [
        version.version.replaceAll(".", "-"),
        {
          openssl:
            date >= SWITCH_TO_OPENSSL_3
              ? "3.0"
              : date >= SWITCH_TO_OPENSSL_1_1
              ? "1.1"
              : "1.0",
          platforms: Object.fromEntries(
            architectures.flatMap((arch) =>
              platforms.flatMap((platform) => {
                const variants = version.downloads.filter(
                  (download) =>
                    (arch === "x86_64"
                      ? arch === download.arch
                      : download.arch === "arm64" ||
                        download.arch === "aarch64") &&
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
        },
      ];
    })
);

writeFileSync("./releases.json", JSON.stringify(releases, null, "\t"));
