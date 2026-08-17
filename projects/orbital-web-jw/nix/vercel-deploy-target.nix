{ pkgs }:

{
  name = "vercel";

  pack = ''
    mkdir -p "$out/.vercel/output/static"
    cp -rL --no-preserve=mode site/. "$out/.vercel/output/static/"
    cp ${./vercel-output-config.json} "$out/.vercel/output/config.json"
  '';

  push =
    {
      name,
      key,
      target,
      output,
    }:
    let
      runner = pkgs.writeShellApplication {
        name = "deploy-${name}-${key}-vercel";
        runtimeInputs = [
          pkgs.bun
          pkgs.coreutils
        ];
        text = ''
          if [ ! -f .vercel/project.json ]; then
            echo "deploy-${name}-${key}-vercel: no .vercel/project.json in $PWD — run 'vercel link' from the project root first" >&2
            exit 1
          fi

          rm -rf .vercel/output
          cp -rL "${output}/.vercel/output" .vercel/output
          chmod -R u+w .vercel/output
          echo "deploying ${target} (prebuilt) -> vercel..."
          exec bunx --bun vercel@59.1.3 deploy --prebuilt "$@"
        '';
      };
    in
    {
      type = "app";
      program = "${runner}/bin/deploy-${name}-${key}-vercel";
      meta.description = "Deploy the prebuilt ${name} ${key} target to Vercel";
    };
}
