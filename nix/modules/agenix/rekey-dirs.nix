{ hostName, scope }:
toString (../../../secrets/rekeyed/${hostName}/${scope})
