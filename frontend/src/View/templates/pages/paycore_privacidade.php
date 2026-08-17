<?php
/**
 * Política de Privacidade do PayCore — página pública, sem sessão.
 *
 * Existe sobretudo por exigência da Google Play, que obriga a um URL público
 * de política de privacidade para publicar a app. O conteúdo descreve o que a
 * aplicação faz de facto: permissões declaradas no AndroidManifest e dados
 * guardados em posstore_prefs. Actualizar aqui quando qualquer um dos dois
 * mudar — uma política que descreva o que a app não faz é pior que nenhuma.
 */
$actualizado = '9 de Agosto de 2026';
?>
<!DOCTYPE html>
<html lang="pt">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Política de Privacidade · PayCore</title>
    <meta name="description" content="Política de privacidade da aplicação PayCore, da E258Tech.">
    <style>
        :root {
            --pp-ground: #f7f8f9;
            --pp-surface: #ffffff;
            --pp-ink: #17212b;
            --pp-soft: #47586a;
            --pp-muted: #6b7c8c;
            --pp-rule: #dde3e8;
            --pp-accent: #10715a;
        }

        * { box-sizing: border-box; }

        body {
            margin: 0;
            background: var(--pp-ground);
            color: var(--pp-ink);
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
            font-size: 16px;
            line-height: 1.7;
        }

        .pp-wrap {
            max-width: 46rem;
            margin: 0 auto;
            padding: clamp(2rem, 5vw, 4rem) clamp(1.1rem, 4vw, 2rem) 5rem;
        }

        .pp-topo {
            border-bottom: 2px solid var(--pp-ink);
            padding-bottom: 1.25rem;
            margin-bottom: 2.5rem;
        }
        .pp-marca {
            font-size: .78rem;
            font-weight: 700;
            letter-spacing: .12em;
            text-transform: uppercase;
            color: var(--pp-accent);
            margin: 0 0 .5rem;
        }
        h1 {
            font-size: clamp(1.7rem, 4vw, 2.3rem);
            line-height: 1.15;
            letter-spacing: -.02em;
            margin: 0 0 .5rem;
            text-wrap: balance;
        }
        .pp-data { font-size: .88rem; color: var(--pp-muted); margin: 0; }

        h2 {
            font-size: 1.15rem;
            letter-spacing: -.01em;
            margin: 2.5rem 0 .75rem;
            padding-top: 1.25rem;
            border-top: 1px solid var(--pp-rule);
        }
        h2:first-of-type { border-top: 0; padding-top: 0; margin-top: 0; }

        p, li { color: var(--pp-soft); }
        p { margin: 0 0 1rem; }
        ul { margin: 0 0 1rem; padding-left: 1.25rem; }
        li { margin-bottom: .45rem; }

        .pp-tabela-scroll { overflow-x: auto; margin: 0 0 1.25rem; }
        table {
            border-collapse: collapse;
            width: 100%;
            min-width: 30rem;
            font-size: .92rem;
            background: var(--pp-surface);
            border: 1px solid var(--pp-rule);
        }
        th, td { text-align: left; padding: .65rem .85rem; border-bottom: 1px solid var(--pp-rule); vertical-align: top; }
        th { font-size: .75rem; text-transform: uppercase; letter-spacing: .07em; color: var(--pp-muted); font-weight: 600; }
        tbody tr:last-child td { border-bottom: 0; }
        td:first-child { font-weight: 600; color: var(--pp-ink); white-space: nowrap; }

        .pp-destaque {
            background: var(--pp-surface);
            border-left: 3px solid var(--pp-accent);
            border-top: 1px solid var(--pp-rule);
            border-right: 1px solid var(--pp-rule);
            border-bottom: 1px solid var(--pp-rule);
            padding: 1.1rem 1.25rem;
            margin: 0 0 1.25rem;
        }
        .pp-destaque p:last-child { margin-bottom: 0; }

        .pp-rodape {
            margin-top: 3rem;
            padding-top: 1.25rem;
            border-top: 1px solid var(--pp-rule);
            font-size: .87rem;
            color: var(--pp-muted);
        }
        a { color: var(--pp-accent); }
    </style>
</head>
<body>
<div class="pp-wrap">

    <header class="pp-topo">
        <p class="pp-marca">E258Tech · PayCore</p>
        <h1>Política de Privacidade</h1>
        <p class="pp-data">Última actualização: <?= htmlspecialchars($actualizado) ?></p>
    </header>

    <h2>Quem somos</h2>
    <p>
        O PayCore é uma aplicação de ponto de venda desenvolvida pela E258Tech,
        em Moçambique. Funciona como cliente do Nexora ERP: os dados que trata
        pertencem à empresa que a utiliza, e é essa empresa quem decide o que
        neles é registado.
    </p>

    <h2>Que dados são tratados</h2>
    <p>
        A aplicação não recolhe dados pessoais de quem a instala para fins
        próprios. Trata apenas o que é necessário para autenticar o operador e
        registar vendas na empresa a que pertence.
    </p>

    <div class="pp-tabela-scroll">
        <table>
            <thead>
                <tr><th>Dados</th><th>Porquê</th></tr>
            </thead>
            <tbody>
                <tr>
                    <td>Credenciais</td>
                    <td>Email e palavra-passe do operador, ou código do terminal e código de activação, para iniciar sessão.</td>
                </tr>
                <tr>
                    <td>Identificação</td>
                    <td>Nome, email, função e empresa do operador, devolvidos pelo servidor após a autenticação.</td>
                </tr>
                <tr>
                    <td>Terminal</td>
                    <td>Identificador, nome e código do terminal em que a aplicação está a ser usada.</td>
                </tr>
                <tr>
                    <td>Vendas</td>
                    <td>Artigos, quantidades, valores e pagamentos, enviados para o sistema da empresa.</td>
                </tr>
            </tbody>
        </table>
    </div>

    <div class="pp-destaque">
        <p>
            A aplicação <strong>não</strong> recolhe localização, contactos,
            fotografias, agenda, histórico de navegação nem identificadores
            publicitários. Não há publicidade, nem partilha de dados com
            terceiros para fins comerciais.
        </p>
    </div>

    <h2>Permissões do dispositivo</h2>
    <p>Cada permissão pedida serve uma função concreta:</p>

    <div class="pp-tabela-scroll">
        <table>
            <thead>
                <tr><th>Permissão</th><th>Para quê</th></tr>
            </thead>
            <tbody>
                <tr>
                    <td>Câmara</td>
                    <td>Ler o código QR que activa o terminal e os códigos de barras dos artigos. As imagens não são guardadas nem enviadas — são processadas no momento e descartadas.</td>
                </tr>
                <tr>
                    <td>Bluetooth</td>
                    <td>Ligar à impressora de recibos. Usado apenas para procurar e comunicar com a impressora.</td>
                </tr>
                <tr>
                    <td>Biometria</td>
                    <td>Desbloquear a sessão com impressão digital, como alternativa ao PIN. A leitura é feita pelo sistema Android e nunca chega à aplicação.</td>
                </tr>
                <tr>
                    <td>Internet</td>
                    <td>Comunicar com o servidor da empresa.</td>
                </tr>
            </tbody>
        </table>
    </div>

    <h2>Onde ficam os dados</h2>
    <p>
        No dispositivo, a aplicação guarda apenas o necessário para manter a
        sessão: os tokens de autenticação, a identificação do operador e do
        terminal, e as permissões atribuídas. Ficam no armazenamento privado da
        aplicação, inacessível a outras aplicações.
    </p>
    <p>
        Os dados de vendas são enviados para o servidor da empresa que utiliza o
        PayCore e ficam sob a responsabilidade dessa empresa. A E258Tech trata-os
        na qualidade de fornecedora do sistema, segundo as instruções do cliente.
    </p>

    <h2>Durante quanto tempo</h2>
    <p>
        Os dados locais são apagados ao terminar sessão ou ao desinstalar a
        aplicação. Os tokens de terminal caducam ao fim de 30 dias. Os dados de
        vendas seguem o prazo de conservação definido pela empresa e pela
        legislação fiscal aplicável.
    </p>

    <h2>Os seus direitos</h2>
    <p>
        Enquanto utilizador, pode pedir acesso, correcção ou eliminação dos seus
        dados. Como esses dados pertencem à empresa que opera o sistema, o pedido
        deve ser dirigido em primeiro lugar a ela. A E258Tech apoia o cliente no
        cumprimento desses pedidos.
    </p>

    <h2>Segurança</h2>
    <p>
        A comunicação com o servidor é feita sempre por HTTPS. As palavras-passe
        e os códigos de activação são guardados no servidor apenas de forma
        cifrada e não podem ser recuperados, só substituídos. O acesso de cada
        operador é limitado às permissões atribuídas pela sua empresa.
    </p>

    <h2>Alterações</h2>
    <p>
        Esta política pode ser actualizada. A data no topo indica a última
        revisão, e o endereço desta página mantém-se.
    </p>

    <h2>Contacto</h2>
    <p>
        Para questões sobre privacidade:
        <a href="mailto:e258tech@gmail.com">e258tech@gmail.com</a>
    </p>

    <div class="pp-rodape">
        E258Tech · PayCore · <a href="https://e258tech.tech">e258tech.tech</a>
    </div>

</div>
</body>
</html>
