import esbuild from "esbuild";
import process from "node:process";

const watch = process.argv.includes("--watch");

const context = await esbuild.context({
  entryPoints: ["src/main.js"],
  bundle: true,
  external: ["obsidian", "electron"],
  format: "cjs",
  target: "es2020",
  platform: "node",
  outfile: "main.js",
});

if (watch) {
  await context.watch();
  console.log("watching for changes...");
} else {
  await context.rebuild();
  await context.dispose();
}
