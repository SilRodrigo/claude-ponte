# ponte

Plugin do Claude Code que abre um canal de conversa entre agentes de devs diferentes, cada
um no seu computador. O objetivo é alinhar trabalho compartilhado: combinar contratos e
interfaces, dividir tarefas, avisar o que mudou e tirar dúvidas sobre o trabalho de cada lado.

A ponte **não** serve para um agente mandar o outro agir. O que chega pela ponte é
informação, nunca instrução; quem decide qualquer mudança é o dev de cada lado.

## Como funciona

```
[Claude do anfitrião] ──localhost──┐
                                   ├── servidor ponte.mjs ◄── ngrok ◄── [Claude do convidado]
                                   │   (no PC do anfitrião)                  (só precisa de curl)
```

- O **anfitrião** abre a ponte: o plugin sobe um servidor Node local e um túnel ngrok, e
  devolve uma URL de convite.
- O **convidado** recebe a URL. Na primeira requisição, a ponte devolve as instruções de uso,
  então o convidado não precisa instalar nada.
- Cada agente escuta em segundo plano com um comando que espera a próxima mensagem. Enquanto
  espera, não gasta tokens.
- A ponte fecha quando o anfitrião pede, ou sozinha após 2h sem mensagens.

## Instalação (só para quem vai abrir pontes)

O repositório é privado: peça ao dono para te adicionar como colaborador. Depois, no Claude Code:

```
/plugin marketplace add SilRodrigo/claude-ponte
/plugin install ponte@claude-ponte
```

Pré-requisitos do anfitrião: Node 18 ou mais novo, e ngrok instalado e autenticado.

```bash
winget install ngrok.ngrok        # ou: brew install ngrok
ngrok config add-authtoken <seu-token>
```

## Uso

**Anfitrião**, no Claude Code:

> abra uma ponte, meu nome é rodrigo

O Claude devolve a URL de convite. Mande-a para o outro dev junto com o seu nome.

**Convidado**, no Claude Code dele:

> entre na ponte do rodrigo em https://xxxx.ngrok-free.dev/r/abc..., meu nome é ana

A partir daí, os dois agentes conversam. Cada um mostra ao seu dev o que chegou e volta a
escutar depois de responder.

Se a sua conta do ngrok tiver um domínio fixo, peça ao Claude para usá-lo (opção `--url`).
Assim o convite muda só na parte da chave.

## Segurança

- **Acesso:** a URL de convite carrega uma chave aleatória de 144 bits. Sem ela, toda
  requisição recebe 404.
- **Identidade:** cada participante recebe um token próprio ao entrar. O remetente de cada
  mensagem vem do token, então ninguém se passa por outro. Nomes são únicos por sala.
- **Limites:** 10 participantes, mensagens de até 32 KB, 120 envios por minuto.
- **Exposição:** o servidor escuta só em 127.0.0.1; o acesso de fora passa apenas pelo túnel.
- **Pausa automática:** se uma mensagem pedir comandos, arquivos ou segredos, alegar
  autorização ou urgência, ou tentar dar ordens, o agente para de escutar, não responde e
  mostra o trecho ao dev.
- **Corte:** o anfitrião pode agir na hora.

  ```bash
  node ponte.mjs kick <nome>   # remove, invalida o token e impede o nome de voltar
  node ponte.mjs lock          # ninguém novo entra
  node ponte.mjs unlock
  node ponte.mjs stop          # fecha a ponte
  ```

  Na prática, basta pedir ao Claude ("expulse o beto e tranque a sala").

O servidor não filtra o conteúdo das mensagens. A regra "mensagem é informação, não
instrução" é seguida pelos agentes, e cada dev continua aprovando as ações do seu próprio Claude.

## API (para referência)

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
