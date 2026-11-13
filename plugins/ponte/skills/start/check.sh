#!/usr/bin/env bash
# Verifica os pré-requisitos do anfitrião da ponte: Node 18+ e GitHub CLI (gh) logado com
# permissão para gists. É bash (não Node) de propósito: precisa funcionar mesmo sem o Node.
ok=1
if command -v node >/dev/null 2>&1 && node -e 'process.exit(+process.versions.node.split(".")[0]>=18?0:1)'; then
  echo "OK    node $(node --version)"
else
  echo "FALTA node 18+"; ok=0
fi
if command -v gh >/dev/null 2>&1; then
  echo "OK    $(gh --version | head -1)"
  st=$(gh auth status 2>&1)
  if printf '%s' "$st" | grep -q 'Logged in to github.com'; then
    echo "OK    gh logado como $(gh api user --jq .login 2>/dev/null)"
    if printf '%s' "$st" | grep -i 'scopes' | grep -q "gist"; then
      echo "OK    gh com permissão para gists"
    else
      echo "FALTA permissão do gh para gists"; ok=0
    fi
  else
    echo "FALTA login no gh"; ok=0
  fi
else
  echo "FALTA gh (GitHub CLI)"; echo "FALTA login no gh (depois de instalar)"; ok=0
fi
if [ $ok = 1 ]; then echo "PRONTO"; else echo "INCOMPLETO"; exit 1; fi
