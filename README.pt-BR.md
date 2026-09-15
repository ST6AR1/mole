[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Français](README.fr.md) | [Español](README.es.md) | [Deutsch](README.de.md) | Português (Brasil)

<p align="center">
  <img src="icon/mole-poses/wordmark-logo.png" width="160" alt="mole logo">
</p>

<p align="center">Esqueça os comandos, vá direto para o trabalho.<br>Skip the commands, get to work.</p>

<p align="center">
  <img src="docs/screenshots/app-icon.png" width="120" alt="mole app icon">
</p>

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Janela principal do mole: solte uma pasta de projeto e ele detecta e inicia automaticamente">
</p>

Um utilitário bem pequeno para macOS: você solta a pasta do projeto, e o mole descobre que tipo de projeto é, roda em segundo plano e abre o navegador — sem empilhar um monte de janelas de Terminal. Você também consegue ver exatamente quais serviços de localhost estão rodando no momento, e parar qualquer um deles com um clique.

## Por que eu criei isso

<p align="center">
  <img src="docs/screenshots/story.png" width="280" alt="Por que eu criei este app">
</p>

Eu não sou desenvolvedor profissional. Depois de muito vibe coding, acabei com cada vez mais projetos, sem lembrar os comandos de start e sempre perdendo a conta de quais portas do localhost ainda estavam rodando.

E eu também não queria ficar perguntando pra uma IA de novo só pra conseguir rodar um projeto.

Então criei o mole. Você solta a pasta, e ele cuida do resto.

## Funcionalidades

- **Início por arrastar e soltar**: solte uma pasta na janela, ou use "Escolher pasta" — o mole detecta o tipo de projeto e o inicia automaticamente. Suporta Node.js (npm / pnpm / yarn / bun), sites estáticos, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensões do Chrome, apps nativos do macOS, entre outros
- **Roda totalmente em segundo plano**: chega de janelas de Terminal se empilhando — a saída do comando de início continua sendo registrada, só que você não precisa mais olhar pra ela
- **Lista de projetos em execução**: cada serviço pega automaticamente o `<title>` ou o favicon do site, para você diferenciar os projetos de relance; os ícones de manter ativo (⭐️) e parar (✕) ficam visíveis e clicáveis direto, sem precisar abrir menu nenhum
- **Fechamento automático**: fecha automaticamente serviços ociosos depois de um tempo configurável; projetos fixados (manter ativo) nunca são afetados
- **Interface em 9 idiomas**: English, 繁體中文, 简体中文, 日本語, 한국어, Français, Español, Deutsch e Português (Brasil) — troque de idioma na hora, direto em Configurações, sem precisar reiniciar o app. A lista de idiomas sempre aparece na mesma ordem fixa, com cada idioma escrito no seu próprio nome nativo
- **Atualização automática**: verifica se há uma versão mais recente ao abrir, com download e instalação em um clique

## Capturas de tela

<p align="center">
  <img src="docs/screenshots/main.png" width="480" alt="Janela principal do mole">
</p>

## Como funciona

Ao soltar uma pasta no mole, ele vai:

1. Examinar o conteúdo da pasta (`package.json`, `Gemfile`, `go.mod`, `Dockerfile`, …) para descobrir o tipo de projeto
2. Montar o comando de início correspondente e rodá-lo em segundo plano (a saída vai para um arquivo de log, nenhuma janela de Terminal aparece)
3. Ficar checando se uma nova porta do localhost apareceu
4. Abrir o navegador automaticamente assim que detectar — ou, se não houver porta web para detectar (um app nativo, um serviço só de backend, etc.), marcar o início como concluído na hora

## Instalação

Requer macOS 12 ou superior.

### Opção 1: Baixar o app

1. Baixe o `mole-x.x.x.dmg` mais recente em [Releases](https://github.com/ST6AR1/mole/releases/latest)
2. Abra o DMG e arraste o app para `Applications`
3. Como não há um certificado pago da Apple Developer, a primeira abertura vai mostrar um aviso de "desenvolvedor não identificado" — no Finder, **clique no app segurando Control → Abrir**, ou libere em **Ajustes do Sistema → Privacidade e Segurança**. Isso só acontece uma vez

### Opção 2: Compilar a partir do código-fonte

```bash
xcode-select --install   # caso ainda não tenha
git clone https://github.com/ST6AR1/mole.git
cd mole
./build.sh
```

Isso gera `mole.app` na pasta do projeto — arraste para `Applications` para usar.

## Plataformas suportadas

Somente macOS 12 (Monterey) ou superior, tanto em Apple Silicon quanto em Intel.

## Privacidade

O mole roda inteiramente na sua própria máquina. Ele não coleta nem envia nenhum dado de uso ou conteúdo dos seus projetos; as únicas chamadas de rede que ele faz são checar no GitHub se há uma versão mais recente ao abrir (uma chamada somente leitura para a API de Releases — nenhuma informação do dispositivo é enviada), e abrir uma página de GitHub Issue já preenchida quando você mesmo clica em "Reportar um problema".

## Perguntas frequentes

**P: Ficou travado em "Waiting for localhost", e agora?**
R: Se for um serviço só de backend, um banco de dados ou um app nativo, simplesmente não existe uma porta web para encontrar, e ele vai se marcar como concluído automaticamente depois de um tempo. Se ainda estiver rodando `npm install`, baixando uma imagem Docker, ou qualquer outra etapa de configuração, confira o log ou o Terminal para ver o progresso real, em vez de soltar a pasta de novo.

**P: Escolhi o idioma errado e não consigo mais ler a interface, o que eu faço?**
R: No menu de idiomas em Configurações, cada idioma aparece no seu próprio nome nativo (por exemplo, "Français", "日本語") e sempre na mesma ordem fixa, então dá pra achar o idioma que você consegue ler sem precisar decifrar mais nada antes.

**P: Quais tipos de projeto são suportados?**
R: Node.js (npm / pnpm / yarn / bun), sites estáticos, Python, Ruby / Rails, Go, Rust, Docker Compose, Deno, PHP, Flutter, Java / Kotlin, .NET, extensões do Chrome, apps nativos do macOS, entre outros — a detecção continua sendo ampliada com o tempo.

## Licença

Licença MIT — veja [LICENSE](LICENSE). Gratuito e open source: use, faça fork, distribua seu próprio build.

## Desenvolvimento

- `App/main.swift`: o código-fonte de todo o app (AppKit puro, sem SwiftUI)
- `App/Localization/`: os arquivos de tradução dos 9 idiomas (`Strings.*.swift`) e a lógica de troca de idioma
- `bin/smart-launch.sh`: o shell script que detecta tipos de projeto e monta os comandos de início
- `build.sh`: compila e empacota o `.app`
- `make-dmg.sh`: empacota um `.dmg` distribuível

Lançando uma nova versão:

```bash
./make-dmg.sh
gh release create vX.Y.Z mole-X.Y.Z.dmg --title "vX.Y.Z" --notes "O que mudou desta vez"
```

## Credits

Made by Wen and Claude, together ⌯^⦁𖥦⦁^⌯
