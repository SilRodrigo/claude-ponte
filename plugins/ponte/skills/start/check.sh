#!/usr/bin/env bash
# Verifica os pré-requisitos do anfitrião da ponte: Node 18+, ngrok e authtoken do ngrok.
# É bash (não Node) de propósito: precisa funcionar mesmo sem o Node instalado.
ok=1
if command -v node >/dev/null 2>&1 && node -e 'process.exit(+process.versions.node.split(".")[0]>=18?0:1)'; then
  echo "OK    node $(node --version)"
else
  echo "FALTA node 18+"; ok=0
fi
if command -v ngrok >/dev/null 2>&1; then
  echo "OK    $(ngrok version)"
  cfg=$(ngrok config check 2>&1 | sed -n 's/.*configuration file at //p' | head -1)
  if [ -n "$cfg" ] && grep -qE '^[[:space:]]*authtoken:[[:space:]]*[^[:space:]]' "$cfg" 2>/dev/null; then
    echo "OK    authtoken do ngrok configurado"
  else
    echo "FALTA authtoken do ngrok"; ok=0
  fi
else
  echo "FALTA ngrok"; echo "FALTA authtoken do ngrok (configurar depois de instalar o ngrok)"; ok=0
fi
if [ $ok = 1 ]; then echo "PRONTO"; else echo "INCOMPLETO"; exit 1; fi
