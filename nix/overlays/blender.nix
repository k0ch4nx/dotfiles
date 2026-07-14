final: prev:

{
  blender = prev.blender.overrideAttrs (
    old:
    let
      oldEnv = old.env or { };
      oldLinkFlags = oldEnv.NIX_CFLAGS_LINK or "";
    in
    {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];

      env = oldEnv // {
        NIX_CFLAGS_LINK =
          if final.lib.hasInfix "-fuse-ld=lld" oldLinkFlags then
            oldLinkFlags
          else if oldLinkFlags == "" then
            "-fuse-ld=lld"
          else
            "${oldLinkFlags} -fuse-ld=lld";
      };
    }
  );
}
