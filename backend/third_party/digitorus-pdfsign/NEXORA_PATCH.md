# Fork local — patch mínimo do Nexora ERP

Esta pasta é uma cópia de `github.com/digitorus/pdfsign` (versão
`v0.0.0-20260407063256-85ede6424a74`, a mais recente disponível no proxy de
módulos Go à data desta alteração — não existem tags/releases semânticas
deste projecto). Usada via `replace` no `go.mod` do backend.

## Porque existe este fork

A biblioteca grava sempre `/SubFilter /adbe.pkcs7.detached` no dicionário de
assinatura do PDF — o formato Adobe PKCS#7 **pré-PAdES**. A norma PAdES (ETSI
EN 319 142) exige `/SubFilter /ETSI.CAdES.detached` para qualquer perfil
(B-B/B-T/B-LT/B-LTA). Este valor está fixo no código-fonte
(`sign/pdfsignature.go`, função `createSignaturePlaceholder`), sem nenhuma
opção de configuração pública. Sem este patch, os PDFs produzidos por este
sistema não são formalmente PAdES — são "PDF com PKCS#7 incorporado" (a
maioria dos leitores comuns ainda reconhece a assinatura, mas um verificador
PAdES/ETSI rigoroso rejeitaria o perfil).

O resto da geração da assinatura (CMS/PKCS#7, atributos CAdES —
`signing-certificate-v2` ESS, `content-type`, `message-digest`,
`signing-time` —, cálculo do ByteRange, suporte a TSA/RFC 3161) já estava
correcto e **não foi alterado**.

Adicionalmente (Fase 7 — segurança e testes): o cliente HTTP usado para
contactar a TSA (`GetTSA`, mesmo ficheiro) não tinha **nenhum timeout** nem
propagava o `context.Context` do chamador. Uma TSA lenta ou indisponível
bloquearia `PDFSigner.Sign()` indefinidamente — e, no nosso fluxo,
`marcarAssinado` (ver `assinatura_transacao.go`) mantém a linha do documento
bloqueada (`SELECT ... FOR UPDATE`) durante a assinatura, pelo que uma TSA
pendurada impediria qualquer outro signatário de avançar nesse documento.
Confirmado com `TestPDFSigner_TSAIndisponivel`.

## Alteração exacta

Dois ficheiros, ambos em `sign/pdfsignature.go`:

- Função `createSignaturePlaceholder`: troca do literal
  `/adbe.pkcs7.detached` por `/ETSI.CAdES.detached` na escrita do dicionário
  de assinatura (`CertType: ApprovalSignature`/`CertificationSignature`/
  `UsageRightsSignature` — a assinatura de carimbo temporal isolado,
  `TimeStampSignature`, usa uma função diferente
  (`createTimestampPlaceholder`) e não foi tocada).
- Função `GetTSA`: `client := &http.Client{}` passou a
  `client := &http.Client{Timeout: 20 * time.Second}`.

Todo o resto do código (incluindo os testes originais da biblioteca, que
continuam a afirmar o valor antigo) é uma cópia fiel do upstream e não corre
como parte da suite de testes deste projecto (este diretório tem o seu
próprio `go.mod`, pelo que `go test ./...` no backend não desce até aqui).

## Como reverter

Se, no futuro, o upstream adicionar uma forma de configurar o `SubFilter`,
ou se decidirmos deixar de precisar deste patch: remover a linha `replace
github.com/digitorus/pdfsign => ./third_party/digitorus-pdfsign` do
`go.mod`, apagar esta pasta, e correr `go mod tidy`.

## Manutenção

Este fork **não** acompanha automaticamente atualizações do upstream. Se o
`digitorus/pdfsign` receber correções de segurança, é preciso repetir este
processo manualmente (copiar a nova versão, reaplicar este patch).
