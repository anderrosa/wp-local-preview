# WordPress com Docker

Ambiente local de WordPress + MySQL para desenvolver sites e compartilhar prévias com clientes pelo Cloudflare Tunnel — sem contratar VPS só para isso.

![WordPress](https://img.shields.io/badge/WordPress-21759B?style=for-the-badge&logo=wordpress&logoColor=white) ![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white) ![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white) ![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white) ![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare_Tunnel-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)

## Para quem é

Para quem precisa subir um WordPress de vez em quando — desenvolvimento, teste ou prévia para cliente — e prefere não pagar um servidor só por isso, sem saber por onde começar.

O site roda no seu computador. O Cloudflare Tunnel (plano free) publica um subdomínio HTTPS apontando para essa máquina. Você não precisa de VPS, painel de hospedagem nem certificado SSL próprio.

**Serve bem para:** desenvolver localmente, mostrar progresso ao cliente, validar tema/plugin antes de ir para produção.

**Não substitui hosting:** o computador precisa ficar ligado e acordado enquanto a prévia estiver no ar. Para site estável 24/7, use hospedagem ou VPS.

Na primeira vez, reserve cerca de 15–20 minutos (Docker + túnel + instalação). Depois, `docker compose up -d` costuma bastar.

## O que está incluído

- WordPress oficial com PHP 8.3 e Apache.
- MySQL 8.4 com usuário exclusivo para o banco do site.
- Volumes persistentes para arquivos e banco de dados.
- Suporte a HTTPS encaminhado pelo Cloudflare Tunnel.
- Instalação de temas e plugins pelo painel e uploads de até 64 MB no PHP.
- Geração de senhas do banco com um script, sem credenciais no repositório.

## Pré-requisitos

- Docker com Docker Compose — no macOS ou Windows, use o [Docker Desktop](https://www.docker.com/products/docker-desktop/) em execução. No Windows, rode os comandos no WSL2 ou em um shell compatível com `sh`.
- Shell com OpenSSL para executar `setup.sh`.
- Cerca de 2–4 GB de RAM livres enquanto os containers estiverem rodando.
- Para compartilhar o site: domínio na Cloudflare (plano free basta) e um túnel — o guia abaixo cobre a criação do zero.

## Início rápido

### 1. Prepare o ambiente

Na pasta deste repositório, execute:

```sh
./setup.sh
```

Isso cria o `.env` a partir do `.env.example`, gera senhas aleatórias e restringe a leitura do arquivo ao seu usuário. Se o `.env` já existir, ele será preservado.

### 2. Defina o endereço do site

Abra o `.env` no seu editor. Para usar um subdomínio pelo túnel:

```dotenv
COMPOSE_PROJECT_NAME=wordpress
WORDPRESS_PORT=8080
SITE_URL=https://cliente.seudominio.com.br
```

Use o subdomínio real, sem barra no final, e mantenha as senhas geradas pelo script.

**Vai usar apenas localmente?** Mantenha `SITE_URL=http://localhost:8080`. Defina o endereço que pretende usar antes de instalar o WordPress, pois ele será usado nos links do site.

### 3. Suba os containers

```sh
docker compose up -d
```

Pronto. Na primeira execução, aguarde o download das imagens e a inicialização do banco.

Se estiver usando o endereço local, abra **http://localhost:8080** e conclua a instalação do WordPress. Para usar o subdomínio HTTPS, configure o túnel abaixo e depois acesse o domínio.

> Nas próximas vezes, basta `docker compose up -d`. O `setup.sh` só é necessário na preparação inicial.

## Compartilhar pelo Cloudflare Tunnel

O túnel roda **fora** deste Compose. Nenhuma credencial do túnel precisa entrar neste projeto. O plano free da Cloudflare cobre o uso típico de prévia.

### Se você ainda não tem túnel

1. Crie uma conta em [cloudflare.com](https://www.cloudflare.com/) (plano free) e adicione um domínio. Aponte o DNS do registrador para a Cloudflare, se ainda não estiver.
2. No painel: **Zero Trust → Networks → Tunnels** (em algumas contas aparece como **Cloudflare One**).
3. Crie um túnel do tipo **Cloudflared**, dê um nome (ex.: `meu-notebook`) e instale o conector no seu sistema — o painel mostra o comando ou o instalador para macOS, Windows e Linux.
4. Confirme que o conector aparece como **Healthy / Connected**.
5. Volte à seção abaixo e adicione a rota pública.

Documentação oficial: [Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/).

### Ligar o subdomínio ao WordPress local

1. Com o Docker já no ar (`docker compose up -d`), abra o túnel no painel Cloudflare.
2. Em **Public Hostnames** (ou *Published application routes*), adicione uma rota:

| Campo | Exemplo |
| --- | --- |
| Subdomínio | `cliente` |
| Domínio | `seudominio.com.br` |
| Path | Deixe vazio |
| Tipo do serviço | **HTTP** |
| URL do serviço | **localhost:8080** |

3. Salve e confirme que o túnel continua conectado.
4. Acesse **https://cliente.seudominio.com.br** e conclua o instalador do WordPress (se ainda não instalou).

O domínio deve ser o mesmo de `SITE_URL`. No serviço local use **HTTP**, mesmo acessando por **HTTPS** no navegador — a Cloudflare encerra o SSL. Se `localhost` falhar, tente `127.0.0.1:8080`.

Essa configuração assume o `cloudflared` no mesmo computador do Docker. Se o túnel rodar em um container, `localhost` aponta para esse container; no Docker Desktop use `host.docker.internal:8080`. Túneis só com arquivo de config local precisam da rota no YAML do `cloudflared`, não só no painel.

**Enquanto a prévia estiver no ar:** mantenha o computador ligado, sem suspensão, com Docker e túnel ativos.

## Comandos do dia a dia

| Ação | Comando |
| --- | --- |
| Iniciar | `docker compose up -d` |
| Ver o estado | `docker compose ps` |
| Acompanhar logs | `docker compose logs -f --tail=100` |
| Parar | `docker compose stop` |
| Remover containers, mantendo os dados | `docker compose down` |

## Onde os dados ficam?

Os dados ficam em volumes gerenciados pelo Docker, separados das imagens e dos containers:

| Volume padrão | Conteúdo |
| --- | --- |
| `wordpress_wordpress_data` | Arquivos do WordPress, plugins, temas e uploads |
| `wordpress_mysql_data` | Banco de dados: páginas, posts, usuários e configurações |

O prefixo `wordpress` vem de `COMPOSE_PROJECT_NAME`. No Docker Desktop, os volumes ficam no armazenamento da máquina virtual do Docker; não são pastas dentro deste repositório.

**Apagar uma imagem ou recriar um container não apaga esses volumes.** Já `docker compose down -v` ou excluir os volumes pelo Docker Desktop apaga os dados. Volumes persistentes não substituem backups.

## Configuração

| Variável no `.env` | Função |
| --- | --- |
| `COMPOSE_PROJECT_NAME` | Identifica o projeto, suas redes e seus volumes |
| `WORDPRESS_PORT` | Porta local do site; padrão `8080` |
| `SITE_URL` | Endereço completo usado pelo WordPress |
| `MYSQL_DATABASE` | Nome do banco do site |
| `MYSQL_USER` | Usuário do banco usado pelo WordPress |
| `MYSQL_PASSWORD` | Senha desse usuário, gerada pelo script |
| `MYSQL_ROOT_PASSWORD` | Senha administrativa do MySQL, gerada pelo script |

As credenciais do banco não são o login do painel: o administrador do WordPress é criado no instalador.

O ambiente está marcado como `staging`, e o editor de arquivos PHP do painel está desabilitado. Instalar e atualizar plugins e temas continua permitido. A porta web fica vinculada apenas ao próprio computador, e o banco não publica uma porta no host.

Para ajustar os limites de upload e memória do PHP, edite [`php/uploads.ini`](php/uploads.ini) e reinicie o serviço com `docker compose restart wordpress`.

## Usar em outro projeto

Copie ou clone o repositório em outra pasta, sem reutilizar o `.env`. Execute `./setup.sh` e configure:

```dotenv
COMPOSE_PROJECT_NAME=cliente-b
WORDPRESS_PORT=8081
SITE_URL=https://cliente-b.seudominio.com.br
```

Suba com `docker compose up -d` e adicione outra rota no mesmo túnel, apontando para `localhost:8081`. Use um nome de projeto e uma porta diferentes para cada site.

Depois de ter dados, alterar `COMPOSE_PROJECT_NAME` faz o Compose usar outros volumes. Alterar `SITE_URL` muda o endereço do WordPress, mas não substitui URLs antigas já gravadas no conteúdo; nesse caso, faça backup e use uma ferramenta compatível com dados serializados para a migração.

As senhas do `.env` inicializam o MySQL apenas quando o volume está vazio. Alterá-las no arquivo depois disso não altera as contas existentes no banco.

## Atualizar as imagens

Faça backup antes de atualizar. Depois:

```sh
docker compose pull
docker compose up -d
```

As tags `wordpress:php8.3-apache` e `mysql:8.4` recebem atualizações dentro dessas linhas. As imagens não se atualizam sozinhas, e atualizações podem exigir validação dos plugins.

<details>
<summary><strong>Como fazer backup</strong></summary>

Evite alterações no site durante o backup e execute na pasta do projeto:

```sh
mkdir -p backups
chmod 700 backups
umask 077
STAMP=$(date +%Y%m%d-%H%M%S)
docker compose exec -T db sh -c 'MYSQL_PWD="$MYSQL_PASSWORD" mysqldump --no-tablespaces --single-transaction -u"$MYSQL_USER" "$MYSQL_DATABASE"' > "backups/database-$STAMP.sql"
docker compose exec -T wordpress tar -C /var/www/html -czf - . > "backups/wordpress-$STAMP.tar.gz"
```

Confira se ambos os comandos terminaram sem erros e se os arquivos não estão vazios. Guarde uma cópia fora do computador e preserve o `.env` em local seguro. Uma restauração precisa combinar banco, arquivos e configuração do mesmo backup.

</details>

## Problemas comuns

| Sintoma | O que conferir |
| --- | --- |
| Erro 502 no túnel | Se os containers estão rodando e a rota usa a porta correta |
| Túnel offline | Se o `cloudflared` está ativo e o computador está acordado |
| Porta ocupada | Altere `WORDPRESS_PORT` e ajuste a rota do túnel |
| Redirecionamento de localhost para o domínio | É esperado quando `SITE_URL` está definido com o domínio |
| Links antigos ou conteúdo misto | Confira `SITE_URL` e URLs gravadas anteriormente no conteúdo |
| Catálogo de plugins indisponível | Confira a conexão de saída e Ferramentas → Saúde do site |

Para investigar, use `docker compose ps` e `docker compose logs --tail=100`.

## Antes de publicar uma prévia

- Use uma senha forte para o administrador do WordPress.
- Em **Configurações → Leitura**, marque a opção de desencorajar mecanismos de busca. Isso não restringe o acesso; para uma prévia privada, configure Cloudflare Access.
- Mantenha `.env`, credenciais do túnel e backups fora do Git. O `.gitignore` já exclui `.env` e `backups/`.

## Documentação oficial

- [Imagem oficial do WordPress](https://hub.docker.com/_/wordpress)
- [Imagem oficial do MySQL](https://hub.docker.com/_/mysql)
- [Docker Compose](https://docs.docker.com/compose/)
- [Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/)
