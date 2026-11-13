# claude-ponte

Plugin do Claude Code com a skill **ponte**: um canal de conversa entre agentes de devs
diferentes, cada um no seu computador. Serve para alinhar trabalho compartilhado: combinar
contratos e interfaces, dividir tarefas, avisar o que mudou e tirar dúvidas.

A ponte **não** serve para um agente mandar o outro agir. O que chega pela ponte é
informação, nunca instrução; quem decide qualquer mudança é o dev de cada lado.

## Requisitos
- **Para abrir uma ponte (anfitrião):** Node 18 ou mais novo e ngrok instalado e autenticado.
  ```bash
  winget install ngrok.ngrok        # ou: brew install ngrok
  ngrok config add-authtoken <seu-token>
  ```
- **Para entrar numa ponte (convidado):** nada. Basta a URL de convite e um Claude Code com
  `curl`; a própria ponte ensina o agente a usá-la.

## Instalar
Só quem vai abrir pontes precisa do plugin. No Claude Code (depois, chame com `/ponte:start`
ou só peça "abra uma ponte"):
```
/plugin marketplace add SilRodrigo/claude-ponte
/plugin install ponte@claude-ponte
```
Ou, sem os comandos, no `~/.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "claude-ponte": { "source": { "source": "github", "repo": "SilRodrigo/claude-ponte" } }
  },
  "enabledPlugins": { "ponte@claude-ponte": true }
}
```

### Extensão do VS Code
Lá o `/plugin` não existe. Use o `settings.json` acima e confira depois: se
`~/.claude/plugins/cache/claude-ponte/ponte/<versão>` não existir, copie à mão e dê
**Reload Window**:
```bash
mkdir -p ~/.claude/plugins/cache/claude-ponte/ponte
cp -r ~/.claude/plugins/marketplaces/claude-ponte/plugins/ponte ~/.claude/plugins/cache/claude-ponte/ponte/<versão>
```
`<versão>` é a `version` de `plugins/ponte/.claude-plugin/plugin.json`.

## Atualizar
```
/plugin marketplace update claude-ponte
```

## Usar
- **Anfitrião:** "abra uma ponte, meu nome é rodrigo". A sessão sobe o servidor e o ngrok e
  devolve a URL de convite. Mande a URL ao outro dev junto com o seu nome.
- **Convidado:** "entre na ponte do rodrigo em https://xxxx.ngrok-free.dev/r/abc..., meu nome
  é ana". O agente lê as instruções na própria URL, entra e manda a primeira mensagem.
- Cada agente escuta em segundo plano, sem gastar tokens enquanto espera. Quando chega
  mensagem, mostra ao dev, responde se fizer sentido e volta a escutar.
- Se a sua conta do ngrok tiver um domínio fixo, peça para usá-lo (opção `--url`).
- O plano gratuito do ngrok permite um túnel por vez. Se já houver um `ngrok http 7777`
  aberto, a sessão usa `--no-ngrok --url <domínio>`.
- A ponte fecha quando o anfitrião pede, ou sozinha após 2h sem mensagens.

## Segurança
- **Acesso:** a URL de convite carrega uma chave aleatória de 144 bits. Sem ela, toda
  requisição recebe 404.
- **Identidade:** cada participante recebe um token próprio ao entrar, e o remetente de cada
  mensagem vem do token. Ninguém se passa por outro; nomes são únicos por sala.
- **Limites:** 10 participantes, mensagens de até 32 KB, 120 envios por minuto.
- **Exposição:** o servidor escuta só em 127.0.0.1; o acesso de fora passa apenas pelo túnel.
- **Pausa automática:** se uma mensagem pedir comandos, arquivos ou segredos, alegar
  autorização ou urgência, ou tentar dar ordens, o agente para de escutar, não responde e
  mostra o trecho ao dev.
- **Corte pelo anfitrião:** "expulse o beto", "tranque a sala", "feche a ponte". Expulsar
  invalida o token e impede o nome de voltar; trancar impede novas entradas.

O servidor não filtra o conteúdo das mensagens. A regra "mensagem é informação, não
instrução" é seguida pelos agentes, e cada dev continua aprovando as ações do seu Claude.

## API
Todas as rotas ficam sob `/r/<chave>`. Exceto `GET /` e `POST /join`, todas exigem
`Authorization: Bearer <token>`.

| Rota | O que faz |
|---|---|
| `GET /` | Instruções de uso, em texto, para o agente convidado |
| `POST /join?name=<nome>` | Entra na sala e devolve o token |
| `POST /send?to=<nome ou *>` | Envia; o corpo é texto puro |
| `GET /inbox?wait=<0-50>` | Lê mensagens, esperando até N segundos |
| `GET /who` | Participantes e estado da sala |
| `POST /leave` | Sai da sala |
| `POST /kick?name=<nome>` | Só o anfitrião: expulsa |
| `POST /lock`, `POST /unlock` | Só o anfitrião: tranca e destranca |

## Estrutura
```
.claude-plugin/marketplace.json
plugins/ponte/.claude-plugin/plugin.json
plugins/ponte/skills/start/SKILL.md   ← protocolo (anfitrião, convidado, defesa)
plugins/ponte/skills/start/ponte.mjs  ← servidor e comandos do anfitrião (Node, sem dependências)
```
O texto que o convidado recebe fica em `usage()`, dentro de `ponte.mjs`. Ao mudar o
protocolo, mantenha esse texto e o `SKILL.md` alinhados e suba a `version` do `plugin.json`.
