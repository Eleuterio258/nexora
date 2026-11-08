# Guia de administração do Ubuntu

Comandos para liberar portas, criar utilizadores, configurar permissões, definir palavras-passe, configurar SSH, instalar Docker, MySQL, PHP, PostgreSQL e PostgREST, publicar com Nginx e HTTPS, automatizar cópias de segurança e manter o servidor.

Execute os comandos `bash` no servidor Ubuntu. Substitua `deploy`, `IP_DO_SERVIDOR` e os caminhos pelos valores do seu ambiente. Os comandos com `sudo` exigem uma conta administrativa. Se quiser usar a conta `ubuntu`, confirme primeiro que existe com `id ubuntu`.

## Índice

- [1. Instalar as ferramentas](#1-instalar-as-ferramentas)
- [2. Liberar portas no firewall](#2-liberar-portas-no-firewall)
- [3. Criar um utilizador](#3-criar-um-utilizador)
- [4. Definir ou mudar a palavra-passe](#4-definir-ou-mudar-a-palavra-passe)
- [5. Configurar permissões](#5-configurar-permissões)
- [6. Ativar o SSH](#6-ativar-o-ssh)
- [7. Configurar uma chave SSH](#7-configurar-uma-chave-ssh)
- [8. Ajustar a configuração do SSH](#8-ajustar-a-configuração-do-ssh)
- [9. Diagnosticar problemas](#9-diagnosticar-problemas)
- [10. Instalar e utilizar Docker](#10-instalar-e-utilizar-docker)
- [11. Instalar e configurar o MySQL](#11-instalar-e-configurar-o-mysql)
- [12. Instalar e configurar o PHP](#12-instalar-e-configurar-o-php)
- [13. Instalar e configurar o PostgreSQL](#13-instalar-e-configurar-o-postgresql)
- [14. Nginx como proxy reverso e HTTPS](#14-nginx-como-proxy-reverso-e-https)
- [15. Instalar e configurar o PostgREST](#15-instalar-e-configurar-o-postgrest)
- [16. Cópias de segurança automáticas](#16-cópias-de-segurança-automáticas)
- [17. Segurança e manutenção](#17-segurança-e-manutenção)
- [18. Publicar a aplicação com Git e Jenkins](#18-publicar-a-aplicação-com-git-e-jenkins)
- [19. Node.js e Python](#19-nodejs-e-python)
- [20. Instalar e configurar o Redis](#20-instalar-e-configurar-o-redis)
- [21. Registos e logrotate](#21-registos-e-logrotate)
- [22. Recuperação de problemas](#22-recuperação-de-problemas)
- [Referências](#referências)

## 1. Instalar as ferramentas

```bash
sudo apt update
sudo apt install ufw openssh-server
```

## 2. Liberar portas no firewall

Consulte as regras existentes:

```bash
sudo ufw status verbose
sudo ufw status numbered
```

Antes de ativar o firewall numa ligação remota, permita a porta usada pelo SSH. O exemplo assume a porta padrão 22; adapte se usar outra.

```bash
sudo ufw allow 22/tcp
```

Execute apenas os exemplos necessários para a sua aplicação:

```bash
# HTTP
sudo ufw allow 80/tcp

# HTTPS
sudo ufw allow 443/tcp

# Aplicação com acesso externo direto
sudo ufw allow 8080/tcp
```

Se a aplicação estiver atrás de Nginx, pode manter a porta interna acessível apenas localmente. Para permitir acesso a uma porta apenas a um IP específico, substitua o endereço de exemplo:

```bash
sudo ufw allow from 192.0.2.10 to any port 8080 proto tcp
```

Uma regra restrita por IP não limita uma regra global existente para a mesma porta. Remova a regra global se quiser restringir o acesso.

Depois de confirmar as regras necessárias, ative o firewall:

```bash
sudo ufw enable
sudo ufw status verbose
```

Para remover a regra global de uma porta:

```bash
sudo ufw delete allow 8080/tcp
```

Também pode usar `sudo ufw delete NUMERO`, com o número mostrado em `status numbered`. Consulte novamente a lista após cada remoção, pois os números mudam.

Liberar uma porta não inicia o serviço. Confira os processos em escuta:

```bash
sudo ss -lntup
```

Um serviço em `127.0.0.1` aceita apenas ligações locais. Confira também o firewall do fornecedor de cloud ou o encaminhamento de portas do router, quando aplicável.

## 3. Criar um utilizador

```bash
sudo adduser deploy
```

O comando cria a pasta pessoal e pede uma palavra-passe. Se a conta precisar de administrar o servidor, atribua o grupo `sudo`:

```bash
sudo usermod -aG sudo deploy
id deploy
```

`-aG` acrescenta o grupo sem remover os existentes. A associação passa a valer numa nova sessão. Teste:

```bash
su - deploy
sudo whoami
exit
```

`sudo whoami` deve apresentar `root` se a conta tiver privilégios administrativos.

## 4. Definir ou mudar a palavra-passe

Para mudar a palavra-passe da conta atual:

```bash
passwd
```

Para definir ou redefinir a palavra-passe de outra conta:

```bash
sudo passwd deploy
```

Introduza a palavra-passe quando solicitada; os caracteres não aparecem no terminal. Definir uma palavra-passe não ativa automaticamente a autenticação por palavra-passe no SSH.

## 5. Configurar permissões

Inspecione o proprietário, grupo e permissões:

```bash
ls -ld /var/www/factpro
ls -l /var/www/factpro
```

Exemplo de pasta de aplicação pertencente a `deploy`:

```bash
sudo mkdir -p /var/www/factpro
sudo chown deploy:deploy /var/www/factpro
sudo chmod 750 /var/www/factpro
```

`chown` altera o proprietário e o grupo. `chmod` altera as permissões:

| Valor | Proprietário | Grupo | Outros | Uso comum |
| --- | --- | --- | --- | --- |
| `700` | Ler, escrever e executar | Sem acesso | Sem acesso | Pasta privada |
| `750` | Ler, escrever e executar | Ler e executar | Sem acesso | Pasta partilhada com o grupo |
| `755` | Ler, escrever e executar | Ler e executar | Ler e executar | Pasta acessível a todos |
| `600` | Ler e escrever | Sem acesso | Sem acesso | Chave privada ou segredo |
| `640` | Ler e escrever | Ler | Sem acesso | Ficheiro partilhado com o grupo |
| `644` | Ler e escrever | Ler | Ler | Ficheiro sem conteúdo sensível |

Numa pasta, executar permite atravessá-la; num ficheiro, permite executá-lo. Ajuste o grupo para a conta que executa a aplicação: a pasta com modo `750` acima não permite acesso a serviços de outro grupo.

Para tornar executável um script existente que pertença à conta atual:

```bash
chmod u+x /var/www/factpro/deploy.sh
```

Evite `chmod 777` e alterações recursivas indiscriminadas, que podem expor segredos ou alterar permissões de executáveis.

## 6. Ativar o SSH

```bash
sudo systemctl enable --now ssh
sudo systemctl status ssh --no-pager
```

Algumas versões do Ubuntu usam ativação por socket. Se necessário, confira também `sudo systemctl status ssh.socket --no-pager`.

No seu computador, ligue-se ao servidor:

```bash
ssh deploy@IP_DO_SERVIDOR
```

Na primeira ligação, confirme a impressão digital do servidor através de uma fonte confiável, como a consola do fornecedor, antes de aceitar.

## 7. Configurar uma chave SSH

No seu computador, gere uma chave e escolha uma frase-passe:

```bash
ssh-keygen -t ed25519 -C "deploy-factpro"
```

Se já existir uma chave no caminho proposto, escolha outro nome para preservar a chave existente. O ficheiro `.pub` é público; mantenha a chave privada no seu computador.

Num cliente Linux com `ssh-copy-id`, copie a chave pública usando um método de autenticação já disponível:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub deploy@IP_DO_SERVIDOR
```

No Windows PowerShell, consulte a chave pública:

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
```

Copie a linha completa. No servidor, entre como `deploy` e acrescente a chave numa nova linha do ficheiro, preservando as chaves existentes:

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Se ainda não conseguir entrar nessa conta, use uma conta administrativa existente ou a consola do fornecedor para instalar a chave em `/home/deploy/.ssh/authorized_keys`, garantindo que a pasta e o ficheiro pertencem a `deploy`.

Teste numa segunda janela, mantendo a sessão atual aberta:

```bash
ssh -i ~/.ssh/id_ed25519 deploy@IP_DO_SERVIDOR
```

Adapte o caminho se tiver escolhido outro nome para a chave.

## 8. Ajustar a configuração do SSH

Depois de confirmar a entrada por chave e o acesso a `sudo`, pode desativar a entrada por palavra-passe e a entrada direta de `root`.

Inspecione `/etc/ssh/sshd_config` e os ficheiros de `/etc/ssh/sshd_config.d/`. Confirme que o ficheiro principal inclui esse diretório. Crie ou edite um snippet local, preservando outras opções existentes:

```bash
sudo nano /etc/ssh/sshd_config.d/00-local.conf
```

Acrescente:

```text
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
```

Para muitas opções, o OpenSSH usa o primeiro valor encontrado. O prefixo `00-` ajuda a dar prioridade entre os snippets, mas configurações anteriores ou blocos `Match` podem influenciar o resultado. Verifique os valores efetivos e valide a sintaxe:

```bash
sudo /usr/sbin/sshd -t
sudo /usr/sbin/sshd -T | grep -E '^(permitrootlogin|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication) '
```

`sshd -t` não apresenta saída quando a configuração é válida. Corrija qualquer erro antes de continuar. Se houver blocos `Match`, use também `sshd -T -C` com os dados da ligação para verificar as opções aplicáveis.

Recarregue o serviço:

```bash
sudo systemctl reload ssh
```

Teste a entrada por chave numa segunda janela e confirme que `sudo` funciona antes de fechar a sessão original.

## 9. Diagnosticar problemas

No servidor:

```bash
sudo systemctl status ssh --no-pager
sudo journalctl -u ssh -n 50 --no-pager
sudo ss -lntp
sudo ufw status verbose
```

No computador cliente:

```bash
ssh -v deploy@IP_DO_SERVIDOR
```

`Connection refused` costuma indicar serviço parado, porta incorreta ou rejeição ativa. Um timeout pode indicar bloqueio de rede ou firewall. Para `Permission denied`, verifique o utilizador, a chave e as permissões de `authorized_keys`.

## 10. Instalar e utilizar Docker

Execute esta secção no servidor Ubuntu. Se já houver uma instalação do Docker, verifique `docker --version` e os pacotes instalados antes de mudar de método. Pacotes como `docker.io`, `podman-docker`, `containerd` e `runc` podem entrar em conflito com os pacotes oficiais; consulte a documentação de instalação e avalie os serviços existentes antes de removê-los.

### Instalar pelo repositório oficial

Instale as dependências e a chave do repositório:

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Configure o repositório para a versão e arquitetura do Ubuntu:

```bash
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Ative e verifique:

```bash
sudo systemctl enable --now docker
sudo systemctl status docker --no-pager
sudo docker run --rm hello-world
sudo docker compose version
```

### Iniciar, parar e reiniciar o Docker

Execute o comando correspondente à ação pretendida:

```bash
# Iniciar
sudo systemctl start docker

# Parar o serviço e o socket que pode reativá-lo
sudo systemctl stop docker.service docker.socket

# Reiniciar
sudo systemctl restart docker

# Ativar no arranque
sudo systemctl enable docker.service docker.socket

# Desativar no arranque e parar agora
sudo systemctl disable --now docker.service docker.socket
```

Parar ou reiniciar o Docker pode interromper os containers. Se `live-restore` estiver configurado, os containers podem continuar em execução mesmo com o daemon parado; para parar uma aplicação específica, use `docker stop`.

### Utilizar sem sudo (opcional)

O grupo `docker` concede privilégios equivalentes aos de administrador. Adicione apenas contas de confiança:

```bash
sudo usermod -aG docker deploy
```

Termine e volte a iniciar a sessão de `deploy` para aplicar a associação. Depois teste `docker run --rm hello-world`. Os exemplos seguintes usam `sudo` e funcionam sem esta alteração.

### Comandos básicos de containers

```bash
# Containers em execução
sudo docker ps

# Todos os containers, incluindo os parados
sudo docker ps -a

# Imagens disponíveis
sudo docker images

# Registos de um container (substitua NOME_DO_CONTAINER)
sudo docker logs --tail 100 NOME_DO_CONTAINER

# Parar, iniciar ou reiniciar um container: escolha a ação necessária
sudo docker stop NOME_DO_CONTAINER
sudo docker start NOME_DO_CONTAINER
sudo docker restart NOME_DO_CONTAINER
```

### Entrar num container

Liste os containers em execução para identificar o nome ou ID:

```bash
sudo docker ps
```

Abra uma sessão interativa dentro do container, substituindo `NOME_DO_CONTAINER`:

```bash
sudo docker exec -it NOME_DO_CONTAINER bash
```

Se a imagem não tiver `bash`, tente `sh`:

```bash
sudo docker exec -it NOME_DO_CONTAINER sh
```

O container precisa de estar em execução e de ter a shell escolhida instalada. Se estiver parado, consulte `sudo docker ps -a` e inicie-o com `sudo docker start NOME_DO_CONTAINER`.

Para entrar no Jenkins do exemplo:

```bash
sudo docker exec -it jenkins bash
```

A sessão usa o utilizador definido no container. Quando precisar de executar uma tarefa administrativa dentro dele, entre como `root`:

```bash
sudo docker exec -it --user root jenkins bash
```

Para sair da sessão sem parar o container:

```bash
exit
```

Alterações feitas dentro do container podem desaparecer quando ele for removido e recriado. Guarde dados persistentes em volumes e inclua alterações permanentes da imagem num Dockerfile.

Com Docker Compose, na pasta do projeto, use o nome do serviço definido no ficheiro Compose:

```bash
sudo docker compose exec NOME_DO_SERVICO bash
# Se bash não estiver disponível:
sudo docker compose exec NOME_DO_SERVICO sh
```

### Docker Compose

Na pasta que contém `compose.yaml` ou `docker-compose.yml`:

```bash
# Validar a configuração
sudo docker compose config --quiet

# Criar e iniciar os serviços
sudo docker compose up -d

# Consultar estado e registos
sudo docker compose ps
sudo docker compose logs --tail 100

# Parar sem remover os containers
sudo docker compose stop

# Retomar os containers existentes
sudo docker compose start
```

Para parar e remover os containers e as redes criadas pelo projeto, use `sudo docker compose down`. Sem `-v`, os volumes nomeados são preservados.

### Portas Docker e firewall

Publicar com `-p 8080:8080` permite acesso pela porta 8080 nas interfaces do servidor. As portas publicadas pelo Docker podem contornar regras do UFW; permitir ou bloquear uma porta apenas no UFW não garante o controlo de acesso ao container.

Se o serviço deve ser acedido apenas pelo próprio servidor ou por um proxy local, publique em loopback:

```bash
# Exemplo de Jenkins acessível localmente, com dados num volume
sudo docker run -d --name jenkins --restart unless-stopped \
  -p 127.0.0.1:8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

Este exemplo só cria um container novo: se já existir um chamado `jenkins`, consulte `sudo docker ps -a` e use `start` ou `restart` conforme necessário. A porta 50000 não é publicada neste exemplo; configure-a apenas se usar agentes Jenkins que precisem dela. Para disponibilizar o Jenkins externamente, configure um proxy com HTTPS e as regras de rede adequadas.

## 11. Instalar e configurar o MySQL

Se a base de dados for executada num container Docker, não instale também o MySQL no servidor: os dois disputariam a porta 3306. Confira antes com `sudo ss -lntp | grep 3306`.

### Instalar (MySQL)

```bash
sudo apt update
sudo apt install mysql-server
sudo systemctl enable --now mysql
sudo systemctl status mysql --no-pager
mysql --version
```

No Ubuntu, a conta `root` do MySQL autentica-se pelo utilizador do sistema (`auth_socket`), sem palavra-passe. Entre como administrador com:

```bash
sudo mysql
```

Execute o assistente de segurança para remover utilizadores anónimos, a base de testes e a entrada remota do `root`:

```bash
sudo mysql_secure_installation
```

Se o assistente pedir uma palavra-passe para o `root`, pode recusar: com `auth_socket`, o acesso continua a ser feito por `sudo mysql`.

### Criar a base de dados e o utilizador da aplicação (MySQL)

Dentro de `sudo mysql`, substitua o nome da base, o utilizador e a palavra-passe:

```sql
CREATE DATABASE factpro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'factpro'@'localhost' IDENTIFIED BY 'PALAVRA_PASSE_FORTE';
GRANT ALL PRIVILEGES ON factpro.* TO 'factpro'@'localhost';
EXIT;
```

`GRANT ... ON factpro.*` limita o utilizador a essa base. Evite `ON *.*` para contas de aplicação. Teste a ligação:

```bash
mysql -u factpro -p factpro
```

### Acesso remoto (MySQL)

Por padrão, o MySQL escuta apenas em `127.0.0.1`. Para administrar a base a partir do seu computador, prefira um túnel SSH, que não exige abrir a porta 3306:

```bash
# No seu computador; depois ligue o cliente a 127.0.0.1:3307
ssh -N -L 3307:127.0.0.1:3306 deploy@IP_DO_SERVIDOR
```

Se outra máquina precisar mesmo de ligação direta, altere `bind-address` em `/etc/mysql/mysql.conf.d/mysqld.cnf` (por exemplo, para o IP privado do servidor ou `0.0.0.0`), crie um utilizador para o IP de origem e libere a porta apenas para esse IP:

```sql
CREATE USER 'factpro'@'192.0.2.10' IDENTIFIED BY 'PALAVRA_PASSE_FORTE';
GRANT ALL PRIVILEGES ON factpro.* TO 'factpro'@'192.0.2.10';
```

```bash
sudo systemctl restart mysql
sudo ufw allow from 192.0.2.10 to any port 3306 proto tcp
```

Não use `'factpro'@'%'` com a porta aberta a qualquer origem.

### Gerir o serviço (MySQL)

```bash
sudo systemctl start mysql
sudo systemctl stop mysql
sudo systemctl restart mysql
sudo journalctl -u mysql -n 50 --no-pager
sudo tail -n 50 /var/log/mysql/error.log
```

### Cópia de segurança e restauro (MySQL)

```bash
# Cópia (consistente para tabelas InnoDB)
sudo mysqldump --single-transaction --routines --triggers factpro > factpro_$(date +%F).sql
chmod 600 factpro_$(date +%F).sql

# Restauro numa base existente
sudo mysql factpro < factpro_AAAA-MM-DD.sql
```

O ficheiro contém todos os dados da base; guarde-o fora do servidor e com permissões restritas. O restauro sobrescreve as tabelas presentes na cópia.

## 12. Instalar e configurar o PHP

### Instalar (PHP)

Instale o PHP-FPM e as extensões mais comuns. Instalar apenas o pacote `php` pode trazer também o Apache; com Nginx, use `php-fpm`:

```bash
sudo apt update
sudo apt install php-fpm php-cli php-mysql php-pgsql php-mbstring php-xml \
  php-curl php-zip php-intl php-gd php-bcmath
php -v
php -m
```

Instale apenas as extensões de base de dados de que precisa (`php-mysql` para MySQL, `php-pgsql` para PostgreSQL). A versão do PHP depende do Ubuntu (por exemplo, 8.3 no 24.04 e 8.1 no 22.04). Identifique o serviço FPM instalado:

```bash
systemctl list-units --type=service 'php*-fpm*'
```

Nos exemplos seguintes, substitua `8.3` pela sua versão.

```bash
sudo systemctl enable --now php8.3-fpm
sudo systemctl status php8.3-fpm --no-pager
```

### Configurar o php.ini

O PHP-FPM e a linha de comandos usam ficheiros diferentes:

- `/etc/php/8.3/fpm/php.ini` — pedidos web
- `/etc/php/8.3/cli/php.ini` — comandos `php`, cron e Composer

Ajuste os valores necessários no ficheiro do FPM:

```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

```ini
date.timezone = Africa/Maputo
memory_limit = 256M
upload_max_filesize = 20M
post_max_size = 25M
max_execution_time = 60
expose_php = Off
```

`post_max_size` deve ser maior que `upload_max_filesize`. Valide e aplique:

```bash
sudo php-fpm8.3 -t
sudo systemctl restart php8.3-fpm
```

### Ligar ao Nginx

```bash
sudo apt install nginx
sudo nano /etc/nginx/sites-available/factpro
```

Exemplo de site com a pasta pública em `/var/www/factpro/public`:

```nginx
server {
    listen 80;
    server_name exemplo.co.mz;
    root /var/www/factpro/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.(?!well-known) {
        deny all;
    }
}
```

Ative o site, valide e recarregue:

```bash
sudo ln -s /etc/nginx/sites-available/factpro /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

As portas 80 e 443 devem estar liberadas no firewall (secção 2). Para HTTPS, siga a secção 14 depois de o domínio apontar para o servidor.

### Permissões da aplicação

O PHP-FPM executa como `www-data`. Com a pasta da secção 5, dê ao grupo `www-data` acesso de leitura e escrita apenas nas pastas que a aplicação altera:

```bash
sudo chown -R deploy:www-data /var/www/factpro
sudo chmod 750 /var/www/factpro
# Apenas nas pastas de escrita da aplicação (exemplo Laravel)
sudo chmod -R g+w /var/www/factpro/storage /var/www/factpro/bootstrap/cache
```

O ficheiro `.env` deve ter modo `640` e nunca ficar dentro da pasta pública.

### Composer

```bash
sudo apt install composer
composer --version
```

Execute o Composer como `deploy`, nunca como `root`:

```bash
cd /var/www/factpro
composer install --no-dev --optimize-autoloader
```

## 13. Instalar e configurar o PostgreSQL

Tal como no MySQL, não instale o PostgreSQL no servidor se a base correr num container que publique a porta 5432. Confira com `sudo ss -lntp | grep 5432`.

### Instalar (PostgreSQL)

```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl enable --now postgresql
sudo systemctl status postgresql --no-pager
pg_lsclusters
```

`pg_lsclusters` mostra a versão, a porta e o estado de cada cluster. Os ficheiros de configuração ficam em `/etc/postgresql/VERSAO/main/`. Para confirmar os caminhos:

```bash
sudo -u postgres psql -c 'SHOW config_file;' -c 'SHOW hba_file;'
```

### Entrar como administrador

O administrador é o utilizador `postgres`, autenticado pelo sistema (`peer`):

```bash
sudo -u postgres psql
```

Comandos úteis dentro do `psql`: `\l` lista bases, `\du` lista utilizadores, `\c NOME` muda de base, `\dt` lista tabelas e `\q` sai.

### Criar a base de dados e o utilizador da aplicação (PostgreSQL)

```bash
sudo -u postgres createuser --pwprompt factpro
sudo -u postgres createdb -O factpro -E UTF8 factpro
```

O utilizador `factpro` não é superutilizador nem pode criar bases ou papéis. Teste por TCP, que usa palavra-passe (pelo socket local seria usada a autenticação `peer`, que exige uma conta Linux com o mesmo nome):

```bash
psql -h 127.0.0.1 -U factpro -d factpro
```

Equivalente em SQL, dentro de `sudo -u postgres psql`:

```sql
CREATE ROLE factpro LOGIN PASSWORD 'PALAVRA_PASSE_FORTE';
CREATE DATABASE factpro OWNER factpro ENCODING 'UTF8';
```

Para mudar a palavra-passe, use `\password factpro` dentro do `psql`, que não a deixa no histórico.

### Acesso remoto (PostgreSQL)

Por padrão, o PostgreSQL escuta apenas em `localhost`. Prefira um túnel SSH:

```bash
# No seu computador; depois ligue o cliente a 127.0.0.1:5433
ssh -N -L 5433:127.0.0.1:5432 deploy@IP_DO_SERVIDOR
```

Se outra máquina precisar de ligação direta, são necessários três passos. Em `postgresql.conf`, defina as interfaces:

```ini
listen_addresses = 'localhost,10.0.0.5'
```

Use o IP do servidor por onde chegam as ligações, ou `'*'` para todas as interfaces. Em `pg_hba.conf`, acrescente uma linha apenas para a base, o utilizador e o IP de origem:

```text
host    factpro    factpro    192.0.2.10/32    scram-sha-256
```

Reinicie (alterar `listen_addresses` exige reinício, não apenas reload) e libere a porta para esse IP:

```bash
sudo systemctl restart postgresql
sudo ufw allow from 192.0.2.10 to any port 5432 proto tcp
```

Evite linhas como `host all all 0.0.0.0/0` e o método `trust`.

### Gerir o serviço (PostgreSQL)

```bash
sudo systemctl start postgresql
sudo systemctl stop postgresql
sudo systemctl restart postgresql
# Aplicar alterações de pg_hba.conf e da maioria dos parâmetros sem reiniciar
sudo systemctl reload postgresql
sudo tail -n 50 /var/log/postgresql/postgresql-*-main.log
```

### Cópia de segurança e restauro (PostgreSQL)

```bash
# Cópia em formato personalizado (comprimido)
sudo -u postgres pg_dump -Fc factpro > factpro_$(date +%F).dump
chmod 600 factpro_$(date +%F).dump

# Restauro numa base vazia pertencente a factpro
sudo -u postgres createdb -O factpro factpro_restauro
sudo -u postgres pg_restore -d factpro_restauro --no-owner --role=factpro < factpro_AAAA-MM-DD.dump
```

Restaurar numa base nova e trocar depois evita apagar a base em uso antes de confirmar que a cópia está íntegra. Os papéis (utilizadores) não fazem parte do `pg_dump`; para os copiar, use `sudo -u postgres pg_dumpall --roles-only`.

## 14. Nginx como proxy reverso e HTTPS

Use o Nginx à frente das aplicações e containers, publicando-os apenas em `127.0.0.1` (secção 10). Assim, só as portas 80 e 443 ficam abertas ao exterior.

### Pré-requisitos

- O domínio (por exemplo `app.exemplo.co.mz`) tem um registo DNS `A` a apontar para o IP público do servidor. Confirme com `dig +short app.exemplo.co.mz`.
- As portas 80 e 443 estão liberadas no UFW e no firewall do fornecedor.

```bash
sudo apt update
sudo apt install nginx
sudo ufw allow 'Nginx Full'
sudo systemctl enable --now nginx
```

O perfil `Nginx Full` libera as portas 80 e 443. Se já as liberou na secção 2, não é necessário.

### Configurar o proxy reverso

Exemplo para uma aplicação que escuta em `127.0.0.1:8000` (o Jenkins da secção 10 já ocupa a 8080; para o publicar, crie outro site igual com o seu domínio e `proxy_pass http://127.0.0.1:8080`):

```bash
sudo nano /etc/nginx/sites-available/app
```

```nginx
server {
    listen 80;
    server_name app.exemplo.co.mz;

    client_max_body_size 25M;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Necessário apenas para WebSockets
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 120s;
    }
}
```

`client_max_body_size` limita o tamanho dos pedidos (por exemplo, uploads); o padrão do Nginx é 1M. Ative, valide e recarregue:

```bash
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
curl -I http://app.exemplo.co.mz
```

Se o site padrão do Nginx responder em vez do seu, confirme o `server_name` ou remova `/etc/nginx/sites-enabled/default`.

### Obter o certificado com Certbot

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d app.exemplo.co.mz
```

O Certbot pede um email para avisos de expiração, obtém o certificado da Let's Encrypt e altera o site para usar HTTPS, incluindo o redireccionamento de HTTP para HTTPS. Para vários domínios no mesmo certificado, repita `-d` para cada um.

Confirme o resultado:

```bash
sudo nginx -t
curl -I https://app.exemplo.co.mz
sudo certbot certificates
```

### Renovação automática

O pacote instala um temporizador systemd que renova os certificados antes de expirarem. Verifique-o e simule uma renovação:

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

A renovação precisa de a porta 80 continuar acessível a partir da Internet. Se `--dry-run` falhar, corrija antes de o certificado expirar (90 dias).

### Diagnosticar o Nginx

```bash
sudo nginx -t
sudo systemctl status nginx --no-pager
sudo tail -n 50 /var/log/nginx/error.log
sudo tail -n 50 /var/log/nginx/access.log
```

`502 Bad Gateway` indica normalmente que a aplicação em `proxy_pass` está parada ou noutra porta; confirme com `sudo ss -lntp`. `504 Gateway Timeout` indica que a aplicação demorou mais do que `proxy_read_timeout`.

## 15. Instalar e configurar o PostgREST

O PostgREST expõe as tabelas, vistas e funções de um schema do PostgreSQL como uma API REST. As permissões da API são as permissões dos papéis do PostgreSQL, por isso a configuração dos papéis é o passo mais importante.

### Preparar a base de dados

Dentro de `sudo -u postgres psql -d factpro`, crie um schema próprio para a API, em vez de expor `public`, e os papéis:

```sql
CREATE SCHEMA api;

-- Papel usado nos pedidos sem token
CREATE ROLE web_anon NOLOGIN;
GRANT USAGE ON SCHEMA api TO web_anon;

-- Papel usado nos pedidos com token JWT válido
CREATE ROLE web_user NOLOGIN;
GRANT USAGE ON SCHEMA api TO web_user;

-- Papel com que o PostgREST se liga; só pode assumir os papéis acima
CREATE ROLE authenticator LOGIN NOINHERIT NOCREATEDB NOCREATEROLE NOSUPERUSER
  PASSWORD 'PALAVRA_PASSE_FORTE';
GRANT web_anon TO authenticator;
GRANT web_user TO authenticator;
```

Conceda depois apenas o necessário a cada papel. Exemplo:

```sql
CREATE VIEW api.produtos AS SELECT id, nome, preco FROM public.produtos;
GRANT SELECT ON api.produtos TO web_anon;
GRANT SELECT, INSERT, UPDATE ON api.produtos TO web_user;
```

Tudo o que `web_anon` puder ler fica acessível publicamente, sem autenticação. Se a API não tiver dados públicos, não conceda nada a `web_anon`.

### Executar com Docker

Guarde a configuração num ficheiro com permissões restritas:

```bash
sudo mkdir -p /etc/postgrest
sudo nano /etc/postgrest/factpro.env
sudo chmod 600 /etc/postgrest/factpro.env
```

```ini
PGRST_DB_URI=postgres://authenticator:PALAVRA_PASSE_FORTE@127.0.0.1:5432/factpro
PGRST_DB_SCHEMAS=api
PGRST_DB_ANON_ROLE=web_anon
PGRST_JWT_SECRET=SEGREDO_ALEATORIO_COM_PELO_MENOS_32_CARACTERES
PGRST_SERVER_HOST=127.0.0.1
PGRST_SERVER_PORT=3000
```

Gere o segredo JWT com `openssl rand -base64 48`. Caracteres especiais na palavra-passe de `PGRST_DB_URI` têm de ser codificados (por exemplo, `@` passa a `%40`).

Com o PostgreSQL instalado no próprio servidor (secção 13), a rede `host` permite ao container ligar-se a `127.0.0.1:5432` sem abrir o PostgreSQL à rede do Docker:

```bash
sudo docker run -d --name postgrest --restart unless-stopped \
  --network host \
  --env-file /etc/postgrest/factpro.env \
  postgrest/postgrest
sudo docker logs --tail 50 postgrest
curl http://127.0.0.1:3000/
```

Com `--network host`, a opção `-p` é ignorada e é `PGRST_SERVER_HOST=127.0.0.1` que mantém a API acessível só localmente. Se o PostgreSQL também correr em Docker, ligue os dois containers à mesma rede Docker e use o nome do container da base em `PGRST_DB_URI`. Fixe uma versão da imagem (por exemplo `postgrest/postgrest:vX.Y.Z`) em produção, para evitar actualizações inesperadas.

### Alternativa: binário com systemd

Descarregue o ficheiro `linux-static-x86-64` da [página de versões](https://github.com/PostgREST/postgrest/releases), extraia e instale:

```bash
tar xJf postgrest-vX.Y.Z-linux-static-x86-64.tar.xz
sudo install -m 0755 postgrest /usr/local/bin/postgrest
sudo adduser --system --group --no-create-home postgrest
sudo chown root:postgrest /etc/postgrest/factpro.env
sudo chmod 640 /etc/postgrest/factpro.env
```

Crie o serviço em `/etc/systemd/system/postgrest.service`:

```ini
[Unit]
Description=PostgREST
After=network.target postgresql.service

[Service]
User=postgrest
EnvironmentFile=/etc/postgrest/factpro.env
ExecStart=/usr/local/bin/postgrest
ExecReload=/bin/kill -USR1 $MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now postgrest
sudo systemctl status postgrest --no-pager
```

### Publicar pelo Nginx

Dentro do bloco `server` do domínio (secção 14), acrescente:

```nginx
location /api/ {
    proxy_pass http://127.0.0.1:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

A barra final em `proxy_pass` remove o prefixo `/api`: `https://app.exemplo.co.mz/api/produtos` chega ao PostgREST como `/produtos`.

### Autenticação e utilização

Os pedidos com o cabeçalho `Authorization: Bearer TOKEN` usam o papel indicado na claim `role` do token, que tem de estar assinado com `PGRST_JWT_SECRET`. Exemplo de conteúdo do token:

```json
{ "role": "web_user", "exp": 1767225600 }
```

Normalmente é o backend da aplicação que emite estes tokens; nunca coloque o segredo JWT no frontend. Exemplos de pedidos:

```bash
curl "http://127.0.0.1:3000/produtos?preco=gt.100&order=nome"
curl -X POST http://127.0.0.1:3000/produtos \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nome": "Exemplo", "preco": 150}'
```

### Recarregar o schema

O PostgREST guarda em cache a estrutura da base. Depois de criar ou alterar tabelas, vistas ou funções no schema `api`, recarregue-a:

```bash
sudo -u postgres psql -d factpro -c "NOTIFY pgrst, 'reload schema';"
```

Também pode usar `sudo docker kill -s SIGUSR1 postgrest` ou, com systemd, `sudo systemctl reload postgrest`.

## 16. Cópias de segurança automáticas

As secções 11 e 13 mostram cópias manuais. Esta secção agenda-as com um temporizador systemd, apaga as cópias antigas e envia-as para fora do servidor. Uma cópia guardada apenas no mesmo servidor não protege contra a perda do disco ou do servidor.

### Script de cópia

Crie `/usr/local/sbin/backup-factpro.sh` e mantenha apenas as partes das bases que usa:

```bash
sudo nano /usr/local/sbin/backup-factpro.sh
```

```bash
#!/usr/bin/env bash
set -euo pipefail
umask 077

DESTINO=/var/backups/factpro
DATA=$(date +%F_%H%M)
RETER_DIAS=14

mkdir -p "$DESTINO"

# PostgreSQL (secção 13)
runuser -u postgres -- pg_dump -Fc factpro > "$DESTINO/pg_factpro_$DATA.dump.tmp"
mv "$DESTINO/pg_factpro_$DATA.dump.tmp" "$DESTINO/pg_factpro_$DATA.dump"

# MySQL (secção 11)
mysqldump --single-transaction --routines --triggers factpro \
  | gzip > "$DESTINO/mysql_factpro_$DATA.sql.gz.tmp"
mv "$DESTINO/mysql_factpro_$DATA.sql.gz.tmp" "$DESTINO/mysql_factpro_$DATA.sql.gz"

# Apagar cópias antigas e restos de execuções falhadas
find "$DESTINO" -type f -name '*.tmp' -mmin +60 -delete
find "$DESTINO" -type f -mtime +"$RETER_DIAS" -delete

# Cópia para outro servidor (opcional; ver abaixo)
# rsync -a -e "ssh -i /root/.ssh/backup_ed25519" "$DESTINO/" backup@IP_BACKUP:/srv/backups/factpro/
```

```bash
sudo chmod 700 /usr/local/sbin/backup-factpro.sh
sudo /usr/local/sbin/backup-factpro.sh
sudo ls -lh /var/backups/factpro
```

O script corre como `root`: o `mysqldump` usa a autenticação `auth_socket` do `root` e o `pg_dump` corre como `postgres`. `set -euo pipefail` faz o script parar no primeiro erro, e o ficheiro `.tmp` evita que uma cópia incompleta pareça válida.

Se a base correr num container, substitua a linha do `pg_dump` por, por exemplo:

```bash
docker exec NOME_DO_CONTAINER pg_dump -U postgres -Fc factpro > "$DESTINO/pg_factpro_$DATA.dump.tmp"
```

### Agendar com systemd

Crie `/etc/systemd/system/backup-factpro.service`:

```ini
[Unit]
Description=Cópia de segurança das bases do factpro

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/backup-factpro.sh
```

E `/etc/systemd/system/backup-factpro.timer`:

```ini
[Unit]
Description=Cópia diária das bases do factpro

[Timer]
OnCalendar=*-*-* 02:30:00
RandomizedDelaySec=10m
Persistent=true

[Install]
WantedBy=timers.target
```

`Persistent=true` executa a cópia em atraso se o servidor estiver desligado à hora marcada. Ative e teste:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now backup-factpro.timer
systemctl list-timers backup-factpro.timer
sudo systemctl start backup-factpro.service
sudo journalctl -u backup-factpro.service -n 50 --no-pager
```

Alternativa com cron: `sudo crontab -e` e acrescente `30 2 * * * /usr/local/sbin/backup-factpro.sh`.

### Enviar para outro servidor

No servidor de produção, crie uma chave só para as cópias, sem frase-passe para poder correr sem intervenção:

```bash
sudo ssh-keygen -t ed25519 -N "" -f /root/.ssh/backup_ed25519 -C "backup-factpro"
sudo cat /root/.ssh/backup_ed25519.pub
```

No servidor de destino, crie um utilizador `backup` sem `sudo` e acrescente a chave pública ao seu `authorized_keys` (secção 7). Teste a ligação uma vez, para aceitar a impressão digital do destino, e depois descomente a linha `rsync` do script:

```bash
sudo ssh -i /root/.ssh/backup_ed25519 backup@IP_BACKUP true
```

O `rsync` sem `--delete` mantém no destino as cópias que já foram apagadas localmente; aplique lá uma política de retenção própria.

### Testar o restauro

Uma cópia só é útil se puder ser restaurada. Periodicamente, restaure a cópia mais recente numa base de teste (secções 11 e 13) e confirme que os dados estão completos. Se o script falhar, o serviço fica no estado `failed`, visível em `systemctl --failed`.

## 17. Segurança e manutenção

### Actualizações automáticas de segurança

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

Por padrão, instala apenas actualizações de segurança. Opções como o reinício automático estão em `/etc/apt/apt.conf.d/50unattended-upgrades`:

```text
Unattended-Upgrade::Automatic-Reboot "false";
```

Teste e consulte o histórico:

```bash
sudo unattended-upgrade --dry-run --debug
sudo tail -n 50 /var/log/unattended-upgrades/unattended-upgrades.log
```

Para actualizar manualmente todos os pacotes:

```bash
sudo apt update
sudo apt upgrade
sudo apt autoremove
```

Se existir o ficheiro `/var/run/reboot-required`, é necessário reiniciar para aplicar a actualização (por exemplo, do kernel). Planeie o reinício e confirme depois que os serviços e containers voltaram a arrancar.

### Fail2ban

O Fail2ban bloqueia temporariamente os IPs com demasiadas tentativas de entrada falhadas.

```bash
sudo apt install fail2ban
sudo nano /etc/fail2ban/jail.local
```

```ini
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1 SEU_IP_FIXO

[sshd]
enabled = true
```

Acrescente o seu IP fixo a `ignoreip` para não ficar bloqueado. Não edite `jail.conf`, que é substituído nas actualizações.

```bash
sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
```

Se o serviço não arrancar por não encontrar o registo do SSH, acrescente `backend = systemd` à secção `[sshd]`. Para desbloquear um IP:

```bash
sudo fail2ban-client set sshd unbanip 192.0.2.10
```

### Espaço em disco

```bash
df -h
sudo du -xh --max-depth=1 /var | sort -h
sudo journalctl --disk-usage
sudo docker system df
```

Para libertar espaço:

```bash
# Registos do journal com mais de 14 dias
sudo journalctl --vacuum-time=14d

# Pacotes descarregados e dependências sem uso
sudo apt clean
sudo apt autoremove

# Containers parados, redes sem uso e imagens sem etiqueta
sudo docker system prune
```

`docker system prune` não apaga volumes, salvo com `--volumes`; não use essa opção sem confirmar que os volumes não têm dados necessários. Com `-a`, apaga também todas as imagens não usadas por containers.

Para limitar os registos dos containers, crie ou edite `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
```

Reinicie o Docker (`sudo systemctl restart docker`). O limite aplica-se apenas aos containers criados depois da alteração.

### Swap

Em servidores com pouca memória, um ficheiro de swap evita que o sistema termine processos quando a memória se esgota. Confirme primeiro se já existe:

```bash
swapon --show
free -h
```

Se não existir, crie um ficheiro de 2 GB:

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

A linha em `/etc/fstab` activa o swap no arranque. Confirme que não ficou duplicada.

### Hora e fuso horário

```bash
timedatectl
sudo timedatectl set-timezone Africa/Maputo
```

`System clock synchronized: yes` indica que a hora está sincronizada. Hora errada afecta registos, certificados, tokens JWT e o agendamento das cópias.

### Monitorização básica

```bash
# Carga, memória e processos
uptime
free -h
top                         # ou htop, depois de sudo apt install htop

# Serviços que falharam e erros desde o último arranque
systemctl --failed
sudo journalctl -p err -b --no-pager | tail -n 50

# Portas em escuta e entradas recentes
sudo ss -lntup
last -n 20
```

Reveja periodicamente:

- `systemctl --failed` e o estado das cópias (secção 16)
- o espaço em disco
- `sudo ufw status numbered` e as portas publicadas pelo Docker (`sudo docker ps`)
- as contas com `sudo` (`getent group sudo`) e as chaves em `authorized_keys`

## 18. Publicar a aplicação com Git e Jenkins

### Chave de deploy para o repositório

No servidor, como `deploy`, crie uma chave só para ler o repositório:

```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/repo_factpro -C "deploy-factpro-repo"
cat ~/.ssh/repo_factpro.pub
```

Adicione a chave pública ao repositório como chave de deploy só de leitura (no GitHub: *Settings → Deploy keys*; no GitLab: *Settings → Repository → Deploy keys*). Indique ao SSH qual a chave a usar, em `~/.ssh/config`:

```text
Host github.com
    IdentityFile ~/.ssh/repo_factpro
    IdentitiesOnly yes
```

```bash
chmod 600 ~/.ssh/config
ssh -T git@github.com
```

Uma chave de deploy dá acesso a um único repositório; não use a sua chave pessoal no servidor.

### Primeira instalação

```bash
sudo apt install git
cd /var/www
git clone git@github.com:ORGANIZACAO/factpro.git factpro
```

Se a pasta já existir (secção 5), clone para uma pasta vazia ou use `git clone ... .` dentro dela. Crie o `.env` a partir do exemplo do projecto e aplique as permissões da secção 12. O `.env` não deve estar no Git.

### Script de deploy

Crie `/var/www/factpro/deploy.sh` fora do controlo do Git (acrescente-o ao `.gitignore`) ou guarde-o no repositório, conforme preferir. Exemplo para uma aplicação PHP:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd /var/www/factpro

git fetch --prune origin
git checkout --quiet main
git merge --ff-only origin/main

composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate --force          # apenas se a aplicação usar migrações Laravel
php artisan config:cache

sudo systemctl reload php8.3-fpm
echo "Deploy concluído: $(git rev-parse --short HEAD)"
```

Exemplo para uma aplicação em Docker Compose:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd /var/www/factpro

git fetch --prune origin
git checkout --quiet main
git merge --ff-only origin/main

docker compose pull
docker compose up -d --build --remove-orphans
docker compose ps
```

```bash
chmod u+x /var/www/factpro/deploy.sh
/var/www/factpro/deploy.sh
```

`merge --ff-only` falha se alguém alterou ficheiros directamente no servidor, em vez de os sobrescrever; corrija a causa antes de repetir. Faça uma cópia da base (secção 16) antes de um deploy com migrações.

Para que `deploy` possa recarregar o PHP-FPM sem palavra-passe, conceda apenas esse comando com `sudo visudo -f /etc/sudoers.d/deploy`:

```text
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl reload php8.3-fpm
```

### Primeiro acesso ao Jenkins

Com o Jenkins da secção 10 em execução, obtenha a palavra-passe inicial:

```bash
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Aceda por túnel SSH (`ssh -N -L 8080:127.0.0.1:8080 deploy@IP_DO_SERVIDOR` e abra `http://localhost:8080`) ou publique-o com Nginx e HTTPS (secção 14). Instale os plugins sugeridos e o plugin **SSH Agent**, e crie uma conta de administrador própria.

Não monte `/var/run/docker.sock` no container do Jenkins sem necessidade: dá ao Jenkins controlo total sobre o servidor.

### Pipeline de deploy por SSH

O Jenkins entra no servidor como `deploy` e executa o script. Gere uma chave própria para o Jenkins:

```bash
ssh-keygen -t ed25519 -N "" -f jenkins_deploy -C "jenkins-deploy"
```

Acrescente `jenkins_deploy.pub` a `/home/deploy/.ssh/authorized_keys` (secção 7). No Jenkins, em *Manage Jenkins → Credentials*, crie uma credencial do tipo *SSH Username with private key* com o ID `deploy-ssh`, o utilizador `deploy` e o conteúdo de `jenkins_deploy`. Apague depois a chave privada do disco.

Crie um `Jenkinsfile` na raiz do repositório:

```groovy
pipeline {
    agent any
    options { disableConcurrentBuilds() }
    stages {
        stage('Testes') {
            steps {
                echo 'Execute aqui os testes do projecto'
            }
        }
        stage('Deploy') {
            when { branch 'main' }
            steps {
                sshagent(credentials: ['deploy-ssh']) {
                    sh 'ssh -o StrictHostKeyChecking=accept-new deploy@IP_DO_SERVIDOR /var/www/factpro/deploy.sh'
                }
            }
        }
    }
}
```

Crie no Jenkins um *Multibranch Pipeline* a apontar para o repositório. `disableConcurrentBuilds()` impede dois deploys em simultâneo. Se o Jenkins correr no mesmo servidor, use o IP do servidor ou `172.17.0.1` (a ponte Docker padrão) em vez de `127.0.0.1`, que dentro do container aponta para o próprio container, e confirme que o UFW permite SSH a partir da rede Docker.

### Voltar à versão anterior

```bash
cd /var/www/factpro
git log --oneline -n 10
git checkout --detach COMMIT_ANTERIOR
```

Repita depois os passos do script a partir de `composer install` (ou `docker compose up -d --build`). Migrações de base de dados não são revertidas pelo Git; se a versão nova alterou a estrutura, restaure a cópia feita antes do deploy (secção 22). Para voltar ao fluxo normal, execute `git checkout main` e o `deploy.sh`.

## 19. Node.js e Python

Execute as aplicações como `deploy` (ou um utilizador próprio), escutando em `127.0.0.1`, e publique-as com o Nginx (secção 14). Use uma porta diferente para cada aplicação.

### Instalar o Node.js

O Node.js dos repositórios do Ubuntu costuma estar desactualizado. Use o repositório da NodeSource com uma versão LTS (consulte as versões em [nodejs.org](https://nodejs.org/)):

```bash
curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
less nodesource_setup.sh        # reveja o script antes de o executar
sudo bash nodesource_setup.sh
sudo apt install nodejs
node -v
npm -v
```

Instale as dependências do projecto como `deploy`:

```bash
cd /var/www/app-node
npm ci --omit=dev
```

`npm ci` instala exactamente as versões de `package-lock.json`.

### Serviço systemd para Node.js

Crie `/etc/systemd/system/app-node.service`:

```ini
[Unit]
Description=Aplicação Node.js
After=network.target

[Service]
User=deploy
WorkingDirectory=/var/www/app-node
Environment=NODE_ENV=production
Environment=PORT=8000
Environment=HOST=127.0.0.1
EnvironmentFile=-/var/www/app-node/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

O ficheiro de arranque (`server.js`) e as variáveis lidas dependem da aplicação. Ative:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now app-node
sudo systemctl status app-node --no-pager
sudo journalctl -u app-node -f
```

O systemd reinicia a aplicação se ela falhar e arranca-a no arranque do servidor, sem precisar de PM2.

### Instalar o Python

```bash
sudo apt install python3 python3-venv python3-pip
python3 --version
```

No Ubuntu 23.04 e posteriores, `pip install` fora de um ambiente virtual é recusado para proteger os pacotes do sistema. Use sempre um ambiente virtual por aplicação:

```bash
cd /var/www/app-python
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install -r requirements.txt
```

### Serviço systemd para Python

Exemplo com Gunicorn (Django, Flask) em `/etc/systemd/system/app-python.service`:

```ini
[Unit]
Description=Aplicação Python
After=network.target

[Service]
User=deploy
WorkingDirectory=/var/www/app-python
EnvironmentFile=-/var/www/app-python/.env
ExecStart=/var/www/app-python/.venv/bin/gunicorn --workers 3 --bind 127.0.0.1:8001 projecto.wsgi:application
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Para FastAPI, use por exemplo `.venv/bin/uvicorn main:app --host 127.0.0.1 --port 8001 --workers 2`. O Gunicorn e o Uvicorn têm de constar de `requirements.txt`. Ative como no Node.js:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now app-python
sudo journalctl -u app-python -n 50 --no-pager
```

Depois de cada deploy, reinicie o serviço (`sudo systemctl restart app-node` ou `app-python`).

## 20. Instalar e configurar o Redis

O Redis é usado como cache, filas e sessões. Não o exponha à Internet: por padrão escuta apenas em `127.0.0.1` e `::1`, e assim deve ficar.

### Instalar (Redis)

```bash
sudo apt update
sudo apt install redis-server
sudo systemctl enable --now redis-server
redis-cli ping
```

`ping` deve responder `PONG`.

### Configurar

Edite `/etc/redis/redis.conf`:

```bash
sudo nano /etc/redis/redis.conf
```

```text
bind 127.0.0.1 ::1
protected-mode yes
requirepass PALAVRA_PASSE_LONGA_E_ALEATORIA

# Uso como cache: limite de memória e remoção das chaves menos usadas
maxmemory 256mb
maxmemory-policy allkeys-lru
```

Gere a palavra-passe com `openssl rand -base64 32`. Se o Redis guardar filas ou sessões que não podem ser perdidas, use `maxmemory-policy noeviction` e active a persistência com `appendonly yes`.

```bash
sudo systemctl restart redis-server
REDISCLI_AUTH='PALAVRA_PASSE' redis-cli ping
REDISCLI_AUTH='PALAVRA_PASSE' redis-cli info memory | head -n 5
```

`REDISCLI_AUTH` evita que a palavra-passe apareça na lista de processos, ao contrário de `redis-cli -a`. Na aplicação, use o URL `redis://:PALAVRA_PASSE@127.0.0.1:6379/0`.

Se uma aplicação num container precisar do Redis do servidor, prefira correr também o Redis num container na mesma rede Docker, em vez de alterar `bind`.

### Gerir o serviço (Redis)

```bash
sudo systemctl restart redis-server
sudo journalctl -u redis-server -n 50 --no-pager
sudo tail -n 50 /var/log/redis/redis-server.log
```

## 21. Registos e logrotate

### Consultar registos com journalctl

```bash
# Registos de um serviço
sudo journalctl -u nginx -n 100 --no-pager

# Acompanhar em tempo real
sudo journalctl -u app-node -f

# Por intervalo de tempo
sudo journalctl -u ssh --since "2026-10-01 08:00" --until "2026-10-01 12:00"

# Apenas erros desde o último arranque
sudo journalctl -p err -b
```

Os registos de texto ficam em `/var/log` (por exemplo `/var/log/nginx`, `/var/log/mysql`, `/var/log/postgresql`, `/var/log/auth.log`).

### Limitar o tamanho do journal

Em `/etc/systemd/journald.conf`, defina:

```ini
[Journal]
SystemMaxUse=500M
```

```bash
sudo systemctl restart systemd-journald
sudo journalctl --disk-usage
```

### Rodar os registos da aplicação

Os pacotes do Ubuntu já configuram a rotação dos seus registos em `/etc/logrotate.d/`. Para os registos da aplicação, crie `/etc/logrotate.d/factpro`:

```text
/var/www/factpro/storage/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    su deploy www-data
    create 0660 deploy www-data
}
```

A linha `su` é necessária porque a pasta pode ser escrita pelo grupo; sem ela o logrotate recusa rodar os ficheiros. Teste sem alterar nada e depois force uma rotação:

```bash
sudo logrotate -d /etc/logrotate.d/factpro
sudo logrotate -f /etc/logrotate.d/factpro
```

O logrotate corre diariamente através de `logrotate.timer`. Se a aplicação mantiver o ficheiro aberto e continuar a escrever no ficheiro rodado, acrescente `copytruncate`.

## 22. Recuperação de problemas

### Perdi o acesso SSH

1. Não feche sessões que ainda estejam abertas.
2. Entre pela consola web do fornecedor (acesso de emergência ou consola VNC/serial).
3. Verifique a configuração e o firewall:

```bash
sudo /usr/sbin/sshd -t
sudo systemctl status ssh --no-pager
sudo ufw status numbered
sudo fail2ban-client status sshd
```

Se o UFW estiver a bloquear, `sudo ufw allow 22/tcp`. Se o Fail2ban bloqueou o seu IP, desbloqueie-o (secção 17). Se o problema for a chave, confirme as permissões de `~/.ssh` (`700`) e de `authorized_keys` (`600`) e o proprietário dos ficheiros.

### Um serviço não arranca

```bash
sudo systemctl status NOME --no-pager
sudo journalctl -u NOME -n 100 --no-pager
sudo ss -lntp                     # a porta está ocupada por outro processo?
df -h                             # o disco está cheio?
```

Valide a configuração antes de reiniciar: `sudo nginx -t`, `sudo /usr/sbin/sshd -t`, `sudo php-fpm8.3 -t`. Depois de corrigir um serviço que falhou várias vezes seguidas, pode ser necessário `sudo systemctl reset-failed NOME`.

### Disco cheio

Siga os passos de *Espaço em disco* (secção 17). As causas mais comuns são registos sem rotação (secção 21), imagens Docker antigas e cópias de segurança locais acumuladas (secção 16). Com o disco cheio, o PostgreSQL e o MySQL podem parar; liberte espaço antes de os reiniciar.

### Restaurar a base de dados

1. Pare a aplicação para evitar escritas durante o restauro (`sudo systemctl stop app-node`, `sudo docker compose stop` ou modo de manutenção da aplicação).
2. Faça uma cópia do estado actual, mesmo que esteja danificado.
3. Restaure para uma base nova e confirme os dados.

PostgreSQL:

```bash
sudo -u postgres pg_dump -Fc factpro > factpro_antes_restauro.dump
sudo -u postgres createdb -O factpro factpro_restauro
sudo -u postgres pg_restore -d factpro_restauro --no-owner --role=factpro < /var/backups/factpro/pg_factpro_AAAA-MM-DD_HHMM.dump
```

Confirme os dados e troque os nomes (não pode haver ligações abertas a nenhuma das bases):

```sql
ALTER DATABASE factpro RENAME TO factpro_antiga;
ALTER DATABASE factpro_restauro RENAME TO factpro;
```

MySQL (não permite mudar o nome de uma base):

```bash
sudo mysqldump --single-transaction factpro > factpro_antes_restauro.sql
sudo mysql -e "CREATE DATABASE factpro_restauro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
gunzip -c /var/backups/factpro/mysql_factpro_AAAA-MM-DD_HHMM.sql.gz | sudo mysql factpro_restauro
```

Confirme os dados e depois restaure a mesma cópia em `factpro`, ou aponte a aplicação para `factpro_restauro` (concedendo-lhe acesso com `GRANT`). Volte a iniciar a aplicação e apague as bases antigas só depois de confirmar que tudo funciona.

### Preparar um servidor novo

Para reconstruir o servidor a partir do zero, siga as secções por esta ordem:

1. Utilizador `deploy`, chave SSH e configuração do SSH (secções 3, 4, 6, 7 e 8)
2. Firewall (secção 2) e segurança (secção 17)
3. Docker, bases de dados e linguagens necessárias (secções 10 a 13, 19 e 20)
4. Restauro das bases a partir da cópia mais recente (esta secção)
5. Aplicação, Nginx e HTTPS (secções 18, 12 e 14)
6. Cópias automáticas e rotação de registos (secções 16 e 21)

Mantenha fora do servidor tudo o que não está no Git: ficheiros `.env`, a configuração do Nginx, os ficheiros de serviço systemd e as cópias de segurança.

## Referências

- [Firewall — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/firewalls/)
- [Gestão de utilizadores — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/security-users/)
- [OpenSSH — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/how-to/security/openssh-server/)
- [Instalar Docker Engine no Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker e firewalls](https://docs.docker.com/engine/network/packet-filtering-firewalls/)
- [MySQL — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/how-to/databases/install-mysql/)
- [PHP — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/how-to/web-services/install-php/)
- [PostgreSQL — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/how-to/databases/install-postgresql/)
- [Autenticação no PostgreSQL (pg_hba.conf)](https://www.postgresql.org/docs/current/auth-pg-hba-conf.html)
- [Nginx como proxy reverso](https://nginx.org/en/docs/http/ngx_http_proxy_module.html)
- [Certbot — instruções para Nginx no Ubuntu](https://certbot.eff.org/instructions)
- [PostgREST — documentação oficial](https://docs.postgrest.org/)
- [Temporizadores systemd (systemd.timer)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)
- [Actualizações automáticas — documentação oficial do Ubuntu](https://ubuntu.com/server/docs/how-to/software/automatic-updates/)
- [Fail2ban](https://github.com/fail2ban/fail2ban)
- [Jenkins — Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Node.js — distribuições NodeSource](https://github.com/nodesource/distributions)
- [Python — ambientes virtuais (venv)](https://docs.python.org/3/library/venv.html)
- [Redis — segurança](https://redis.io/docs/latest/operate/oss_and_stack/management/security/)
- [logrotate](https://manpages.ubuntu.com/manpages/noble/man8/logrotate.8.html)
