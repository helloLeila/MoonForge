#!/usr/bin/env node

/**
 * 文件说明：
 * 这个文件不是 MoonForge 的核心逻辑。
 * 它只是 npm 入口，负责做两件事：
 * 1. 判断当前平台应该下载哪个二进制
 * 2. 把下载到本地缓存的 moonforge 可执行文件真正跑起来
 *
 * 这样用户即使通过 npm 安装，真正执行的仍然是独立 CLI。
 */

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const https = require("node:https");
const childProcess = require("node:child_process");

const packageJson = require("../package.json");

function resolveAssetName() {
  const platform = process.platform;
  const arch = process.arch;
  if (platform === "darwin" && arch === "arm64") {
    return "moonforge-darwin-arm64";
  }
  if (platform === "darwin" && arch === "x64") {
    return "moonforge-darwin-x64";
  }
  if (platform === "linux" && arch === "x64") {
    return "moonforge-linux-x64";
  }
  throw new Error(
    `MoonForge npm entry does not support ${platform}/${arch} yet.`,
  );
}

function resolveDownloadUrl(assetName) {
  const repo = process.env.MOONFORGE_GITHUB_REPO || "helloLeila/MoonForge";
  const version = packageJson.version;
  return `https://github.com/${repo}/releases/download/v${version}/${assetName}`;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function downloadFile(url, destination) {
  return new Promise((resolve, reject) => {
    const request = https.get(
      url,
      {
        headers: {
          "User-Agent": "moonforge-npm-wrapper",
        },
      },
      (response) => {
        if (
          response.statusCode &&
          response.statusCode >= 300 &&
          response.statusCode < 400 &&
          response.headers.location
        ) {
          response.resume();
          downloadFile(response.headers.location, destination)
            .then(resolve)
            .catch(reject);
          return;
        }
        if (response.statusCode !== 200) {
          reject(
            new Error(
              `Failed to download MoonForge binary: ${response.statusCode}`,
            ),
          );
          response.resume();
          return;
        }
        const file = fs.createWriteStream(destination, { mode: 0o755 });
        response.pipe(file);
        file.on("finish", () => {
          file.close(() => resolve());
        });
        file.on("error", (error) => {
          reject(error);
        });
      },
    );
    request.on("error", reject);
  });
}

async function ensureBinary() {
  const assetName = resolveAssetName();
  const cacheDir = path.join(
    os.homedir(),
    ".moonforge",
    "npm-bin",
    packageJson.version,
  );
  const binaryPath = path.join(cacheDir, "moonforge");
  if (fs.existsSync(binaryPath)) {
    return binaryPath;
  }
  ensureDir(cacheDir);
  const tempPath = `${binaryPath}.download`;
  await downloadFile(resolveDownloadUrl(assetName), tempPath);
  fs.chmodSync(tempPath, 0o755);
  fs.renameSync(tempPath, binaryPath);
  return binaryPath;
}

async function main() {
  try {
    const binaryPath = await ensureBinary();
    const result = childProcess.spawnSync(binaryPath, process.argv.slice(2), {
      stdio: "inherit",
    });
    if (typeof result.status === "number") {
      process.exit(result.status);
    }
    if (result.error) {
      throw result.error;
    }
    process.exit(1);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`MoonForge npm entry failed: ${message}`);
    process.exit(1);
  }
}

main();
