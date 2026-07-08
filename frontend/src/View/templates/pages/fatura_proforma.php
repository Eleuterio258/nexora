<?php

    $idHash = $app->request->queryString('id');

    $resp = $app->nexora->call('GET', "/api/faturacao/invoices/$idHash");
    if ($resp['status'] !== 200) {
        header('Location: /nexora/faturacao/faturas');
        exit;
    }
    $fatura = $resp['body']['fatura'] ?? [];
    $itens  = $resp['body']['itens'] ?? [];

    $customerId = $fatura['customer_id'];
    $cliente    = $app->nexora->call('GET', '/api/clientes/' . $customerId)['body'] ?? [];

    $clienteEnderecos = $app->nexora->call('GET', '/api/clientes/' . $customerId . '/enderecos')['body'] ?? [];
    $clienteEndereco  = null;
    foreach ($clienteEnderecos as $e) {
        if (! empty($e['principal'])) { $clienteEndereco = $e; break; }
    }
    $clienteEndereco ??= $clienteEnderecos[0] ?? null;

    $companies = $app->nexora->call('GET', '/api/companies')['body'] ?? [];
    $company   = $companies[0] ?? null;

    $tax = $companyEndereco = $companyContacto = null;
    if ($company) {
        $cid = $company['id'];

        $tax = $app->nexora->call('GET', "/api/companies/$cid/tax-info")['body'] ?? null;

        $addrs = $app->nexora->call('GET', "/api/companies/$cid/addresses")['body'] ?? [];
        foreach ($addrs as $a) {
            if (($a['tipo'] ?? '') === 'principal') { $companyEndereco = $a; break; }
        }
        $companyEndereco ??= $addrs[0] ?? null;

        $contacts = $app->nexora->call('GET', "/api/companies/$cid/contacts")['body'] ?? [];
        foreach ($contacts as $c) {
            if (! empty($c['principal'])) { $companyContacto = $c; break; }
        }
        $companyContacto ??= $contacts[0] ?? null;
    }

    $companyNome = ! empty($company['nome_comercial']) ? $company['nome_comercial'] : ($company['nome'] ?? '—');

    $subtotal      = 0.0;
    $descontoTotal = 0.0;
    foreach ($itens as $item) {
        $base = (float) $item['quantidade'] * (float) $item['preco_unitario'];
        $subtotal      += $base;
        $descontoTotal += $base * (float) $item['desconto_percent'] / 100;
    }

    $pageTitle = 'Fatura Pró-forma ' . ($fatura['numero'] ?? '');

    $docTitulo = 'FATURA PRÓ-FORMA';
    $docNumero = $fatura['numero'] ?? '';

    $docDatasExtra = [
        'Data de emissão' => $fatura['invoice_date'] ? date('d/m/Y', strtotime($fatura['invoice_date'])) : '—',
    ];
    if (! empty($fatura['due_date'])) {
        $docDatasExtra['Válido até'] = date('d/m/Y', strtotime($fatura['due_date']));
    }

    $notice = 'Documento sem valor fiscal — válido apenas para fins informativos/pró-forma. Não substitui a fatura oficial.';

    $impostoTotal = (float) ($fatura['imposto_total'] ?? 0);
    $totalGeral   = (float) ($fatura['total'] ?? 0);
    $moeda        = $fatura['moeda'] ?? '';
    $observacoes  = $fatura['observacoes'] ?? null;

    $footerNote = 'Documento gerado em ' . date('d/m/Y H:i') . ' — sem validade fiscal.';
    $backUrl    = '/nexora/faturacao/faturas/form?id=' . $idHash;

    include dirname(__DIR__) . '/partials/documento_print.php';
