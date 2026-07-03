<?php
declare(strict_types=1);

namespace E258Tech\Controller\Admin\Api;

use E258Tech\Controller\Admin\AdminApiDependencies;
use E258Tech\Http\ApiResult;
use E258Tech\Http\Request;
use E258Tech\Model\Exception\OperationException;

final class RecursosHumanosController
{
    public function rhAusenciaAprovar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->approveLeave($request->int('id') ?? 0));
    }

    public function rhAusenciaCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->cancelLeave($request->int('id') ?? 0));
    }

    public function rhAusenciaGozar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->markLeaveTaken($request->int('id') ?? 0));
    }

    public function rhAusenciaRejeitar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'motivo' => $request->string('motivo') ?: null,
        ];

        return $d->result(fn() => $d->rh->rejectLeave($request->int('id') ?? 0, $payload));
    }

    public function rhAusenciaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'funcionario_id' => $request->int('funcionario_id') ?? 0,
            'tipo_id' => $request->int('tipo_id') ?? 0,
            'data_inicio' => $request->string('data_inicio'),
            'data_fim' => $request->string('data_fim'),
            'motivo' => $request->string('motivo') ?: null,
        ];

        return $d->result(fn() => $d->rh->createLeaveRequest($payload));
    }

    public function rhAvaliacaoAprovar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->approveEvaluation($request->int('id') ?? 0));
    }

    public function rhAvaliacaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $criterios = [];
        foreach ((array) ($request->all()['criterios'] ?? []) as $c) {
            $criterioId = (int) ($c['criterio_id'] ?? 0);
            if ($criterioId > 0) {
                $criterios[] = ['criterio_id' => $criterioId, 'pontuacao' => (float) ($c['pontuacao'] ?? 0)];
            }
        }

        $payload = [
            'funcionario_id' => $request->int('funcionario_id') ?? 0,
            'periodo_id' => $request->int('periodo_id') ?? 0,
            'comentarios' => $request->string('comentarios') ?: null,
            'criterios' => $criterios,
        ];

        return $d->result(fn() => $d->rh->createEvaluation($payload));
    }

    public function rhAvaliacaoSubmeter(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->submitEvaluation($request->int('id') ?? 0));
    }

    public function rhBeneficioRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteBenefit($request->int('id') ?? 0));
    }

    public function rhBeneficioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'valor_padrao' => $request->float('valor_padrao'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
                'valor_padrao' => $request->float('valor_padrao'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveBenefit($id, $payload));
    }

    public function rhCargoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deletePosition($request->int('id') ?? 0));
    }

    public function rhCargoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'salario_min' => $request->float('salario_min'),
                'salario_max' => $request->float('salario_max'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
                'salario_min' => $request->float('salario_min'),
                'salario_max' => $request->float('salario_max'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->savePosition($id, $payload));
    }

    public function rhComponenteSalarialRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteSalaryComponent($request->int('id') ?? 0));
    }

    public function rhComponenteSalarialSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'tipo' => $request->string('tipo') ?: null,
                'forma_calculo' => $request->string('forma_calculo') ?: null,
                'valor_padrao' => $request->float('valor_padrao'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'tipo' => $request->string('tipo'),
                'forma_calculo' => $request->string('forma_calculo') ?: null,
                'valor_padrao' => $request->float('valor_padrao'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveSalaryComponent($id, $payload));
    }

    public function rhContactoEmergenciaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteEmergencyContact($request->int('id') ?? 0));
    }

    public function rhContactoEmergenciaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'funcionario_id' => $request->int('funcionario_id') ?? 0,
            'nome' => $request->string('nome'),
            'parentesco' => $request->string('parentesco') ?: null,
            'telefone' => $request->string('telefone'),
            'email' => $request->string('email') ?: null,
        ];

        return $d->result(fn() => $d->rh->createEmergencyContact($payload));
    }

    public function rhContratoFicheiro(Request $request, AdminApiDependencies $d): ApiResult
    {
        // Este endpoint usa bootstrap directo — não passa pelo kernel padrão.
        // Mantém a lógica de ficheiro aqui para compatibilidade com dispatch().
        $authorization = new \E258Tech\Infrastructure\Auth\PhpSessionAuthorization();
        if (!$authorization->isAuthenticated() || !$authorization->can('recursos-humanos', 'gerir_contratos')) {
            return new ApiResult(['erro' => 'Sem permissao.'], 403);
        }

        $path = (string) ($_GET['path'] ?? '');

        // Suporte a ficheiros guardados no storage remoto (MinIO/S3).
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            $data = @file_get_contents($path);
            if ($data === false) {
                return new ApiResult(['erro' => 'Ficheiro nao disponivel.'], 404);
            }
            $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
            $mimeTypes = [
                'pdf' => 'application/pdf', 'doc' => 'application/msword',
                'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png',
            ];
            header('Content-Type: ' . ($mimeTypes[$ext] ?? 'application/octet-stream'));
            header('Content-Disposition: inline; filename="contrato.' . $ext . '"');
            header('Content-Length: ' . (string) strlen($data));
            echo $data;
            exit;
        }

        if (!preg_match('/^rh-contratos\/[a-f0-9]{32}\.(pdf|docx?|jpe?g|png)$/i', $path)) {
            return new ApiResult([], 404);
        }

        $fullPath = dirname(__DIR__, 4) . '/uploads/' . $path;
        if (!is_file($fullPath)) {
            return new ApiResult([], 404);
        }

        $mimeTypes = [
            'pdf' => 'application/pdf', 'doc' => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png',
        ];
        $ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

        header('Content-Type: ' . ($mimeTypes[$ext] ?? 'application/octet-stream'));
        header('Content-Disposition: inline; filename="' . basename($fullPath) . '"');
        header('Content-Length: ' . (string) filesize($fullPath));
        readfile($fullPath);
        exit;
    }

    public function rhContratoPdf(Request $request, AdminApiDependencies $d): ApiResult
    {
        $authorization = new \E258Tech\Infrastructure\Auth\PhpSessionAuthorization();
        if (!$authorization->isAuthenticated() || !$authorization->can('recursos-humanos', 'gerir_contratos')) {
            return new ApiResult(['erro' => 'Sem permissao.'], 403);
        }

        $id = (int) ($_GET['id'] ?? 0);
        if ($id <= 0) {
            return new ApiResult(['erro' => 'Contrato invalido.'], 400);
        }

        $binary = $d->rh->downloadContractPdf($id);
        if ($binary['status'] !== 200 || empty($binary['body'])) {
            return new ApiResult(['erro' => 'PDF nao disponivel.'], $binary['status'] ?? 404);
        }

        header('Content-Type: application/pdf');
        header('Content-Disposition: inline; filename="contrato-' . $id . '.pdf"');
        header('Content-Length: ' . (string) strlen($binary['body']));
        echo $binary['body'];
        exit;
    }

    public function rhContratoRenovar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->renewContract($request->int('id') ?? 0, [
            'data_fim' => $request->string('data_fim'),
            'salario' => $request->float('salario'),
        ]));
    }

    public function rhContratoRescindir(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->terminateContract($request->int('id') ?? 0, [
            'data_fim' => $request->string('data_fim') ?: null,
        ]));
    }

    public function rhContratoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $id = $request->int('id');
            $ficheiroUrl = null;

            if (!empty($_FILES['ficheiro']['name']) && $_FILES['ficheiro']['error'] === UPLOAD_ERR_OK) {
                $allowedExt = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
                $maxSize    = 10 * 1024 * 1024;

                $ext = strtolower(pathinfo((string) $_FILES['ficheiro']['name'], PATHINFO_EXTENSION));
                if (!in_array($ext, $allowedExt, true)) {
                    throw new OperationException('Tipo de ficheiro não permitido. Use PDF, DOC, DOCX, JPG ou PNG.');
                }
                if ($_FILES['ficheiro']['size'] > $maxSize) {
                    throw new OperationException('O ficheiro excede o tamanho máximo de 10MB.');
                }

                $dir = dirname(__DIR__, 4) . '/uploads/rh-contratos';
                if (!is_dir($dir)) {
                    mkdir($dir, 0755, true);
                }

                $filename = bin2hex(random_bytes(16)) . '.' . $ext;
                if (!move_uploaded_file($_FILES['ficheiro']['tmp_name'], "$dir/$filename")) {
                    throw new OperationException('Erro ao guardar o ficheiro.');
                }

                $ficheiroUrl = "rh-contratos/$filename";
            }

            if ($id) {
                $payload = [
                    'tipo' => $request->string('tipo') ?: null,
                    'funcao' => $request->string('funcao') ?: null,
                    'data_inicio' => $request->string('data_inicio') ?: null,
                    'data_fim' => $request->string('data_fim') ?: null,
                    'salario' => $request->float('salario'),
                    'ficheiro_url' => $ficheiroUrl,
                ];

                $result = $d->rh->updateContract($id, $payload);
                $contractId = $id;
            } else {
                $payload = [
                    'funcionario_id' => $request->int('funcionario_id') ?? 0,
                    'tipo' => $request->string('tipo'),
                    'funcao' => $request->string('funcao') ?: null,
                    'data_inicio' => $request->string('data_inicio'),
                    'data_fim' => $request->string('data_fim') ?: null,
                    'salario' => $request->float('salario'),
                    'ficheiro_url' => $ficheiroUrl,
                ];

                $result = $d->rh->createContract($payload);
                $contractId = (int) ($result['id'] ?? 0);
            }

            // Se não foi feito upload manual, gera PDF automaticamente e guarda no storage.
            if ($ficheiroUrl === null && $contractId > 0) {
                $comParticipacao = ($request->string('participacao') ?? '0') === '1';
                $this->generateAndStoreContractPdf($d, $contractId, $comParticipacao);
            }

            return $result;
        });
    }

    private function generateAndStoreContractPdf(AdminApiDependencies $d, int $contractId, bool $comParticipacao): void
    {
        // Obter contrato e funcionário
        try {
            $contract = $d->rh->getContract($contractId);
        } catch (OperationException) {
            return;
        }

        $funcionarioId = (int) ($contract['funcionario_id'] ?? 0);
        if ($funcionarioId <= 0) {
            return;
        }

        try {
            $employeeData = $d->rh->getEmployee($funcionarioId);
        } catch (OperationException) {
            return;
        }

        $empresa = [
            'nome'   => 'e258tech, Lda',
            'nuit'   => '402134951',
            'morada' => 'Maputo, Moçambique',
        ];

        $builder = new \E258Tech\Infrastructure\Pdf\ContratoE258TechBuilder();
        $pdf = $builder->build([
            'empresa'     => $empresa,
            'funcionario' => $employeeData['funcionario'] ?? [],
            'contrato'    => $contract,
        ], $comParticipacao);

        $d->rh->saveContractPdf($contractId, $pdf);
    }

    public function rhCriterioAvaliacaoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteEvaluationCriterion($request->int('id') ?? 0));
    }

    public function rhCriterioAvaliacaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'peso' => $request->float('peso'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
                'peso' => $request->float('peso'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveEvaluationCriterion($id, $payload));
    }

    public function rhDocumentoFicheiro(Request $request, AdminApiDependencies $d): ApiResult
    {
        $authorization = new \E258Tech\Infrastructure\Auth\PhpSessionAuthorization();
        if (!$authorization->isAuthenticated() || !$authorization->can('recursos-humanos', 'ver_funcionarios')) {
            return new ApiResult(['erro' => 'Sem permissao.'], 403);
        }

        $path = (string) ($_GET['path'] ?? '');

        if (!preg_match('/^rh-documentos\/[a-f0-9]{32}\.(pdf|docx?|jpe?g|png)$/i', $path)) {
            return new ApiResult([], 404);
        }

        $fullPath = dirname(__DIR__, 4) . '/uploads/' . $path;
        if (!is_file($fullPath)) {
            return new ApiResult([], 404);
        }

        $mimeTypes = [
            'pdf' => 'application/pdf', 'doc' => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'jpg' => 'image/jpeg', 'jpeg' => 'image/jpeg', 'png' => 'image/png',
        ];
        $ext = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

        header('Content-Type: ' . ($mimeTypes[$ext] ?? 'application/octet-stream'));
        header('Content-Disposition: inline; filename="' . basename($fullPath) . '"');
        header('Content-Length: ' . (string) filesize($fullPath));
        readfile($fullPath);
        exit;
    }

    public function rhDocumentoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $resultado = $d->rh->deleteDocument($request->int('id') ?? 0);

            $ficheiroUrl = $resultado['ficheiro_url'] ?? null;
            if ($ficheiroUrl && preg_match('/^rh-documentos\/[a-f0-9]{32}\.(pdf|docx?|jpe?g|png)$/i', (string) $ficheiroUrl)) {
                $fullPath = dirname(__DIR__, 4) . '/uploads/' . $ficheiroUrl;
                if (is_file($fullPath)) {
                    unlink($fullPath);
                }
            }

            unset($resultado['ficheiro_url']);

            return $resultado;
        });
    }

    public function rhDocumentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $ficheiroUrl = null;

            if (!empty($_FILES['ficheiro']['name']) && $_FILES['ficheiro']['error'] === UPLOAD_ERR_OK) {
                $allowedExt = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];
                $maxSize    = 10 * 1024 * 1024;

                $ext = strtolower(pathinfo((string) $_FILES['ficheiro']['name'], PATHINFO_EXTENSION));
                if (!in_array($ext, $allowedExt, true)) {
                    throw new OperationException('Tipo de ficheiro não permitido. Use PDF, DOC, DOCX, JPG ou PNG.');
                }
                if ($_FILES['ficheiro']['size'] > $maxSize) {
                    throw new OperationException('O ficheiro excede o tamanho máximo de 10MB.');
                }

                $dir = dirname(__DIR__, 4) . '/uploads/rh-documentos';
                if (!is_dir($dir)) {
                    mkdir($dir, 0755, true);
                }

                $filename = bin2hex(random_bytes(16)) . '.' . $ext;
                if (!move_uploaded_file($_FILES['ficheiro']['tmp_name'], "$dir/$filename")) {
                    throw new OperationException('Erro ao guardar o ficheiro.');
                }

                $ficheiroUrl = "rh-documentos/$filename";
            }

            $payload = [
                'funcionario_id' => $request->int('funcionario_id') ?? 0,
                'tipo' => $request->string('tipo'),
                'numero' => $request->string('numero') ?: null,
                'data_emissao' => $request->string('data_emissao') ?: null,
                'data_validade' => $request->string('data_validade') ?: null,
                'ficheiro_url' => $ficheiroUrl,
            ];

            return $d->rh->createDocument($payload);
        });
    }

    public function rhFolhaPagamentoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->cancelPayrollRun($request->int('id') ?? 0));
    }

    public function rhFolhaPagamentoPagar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->payPayrollRun($request->int('id') ?? 0));
    }

    public function rhFolhaPagamentoProcessar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->processPayrollRun($request->int('id') ?? 0));
    }

    public function rhFolhaPagamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'ano' => $request->int('ano') ?? 0,
            'mes' => $request->int('mes') ?? 0,
        ];

        return $d->result(fn() => $d->rh->createPayrollRun($payload));
    }

    public function rhFormacaoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteTraining($request->int('id') ?? 0));
    }

    public function rhFormacaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'categoria' => $request->string('categoria') ?: null,
                'duracao_horas' => $request->float('duracao_horas'),
                'entidade_formadora' => $request->string('entidade_formadora') ?: null,
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
                'categoria' => $request->string('categoria') ?: null,
                'duracao_horas' => $request->float('duracao_horas'),
                'entidade_formadora' => $request->string('entidade_formadora') ?: null,
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveTraining($id, $payload));
    }

    public function rhFuncionarioBeneficioRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->removeEmployeeBenefit(
            $request->int('funcionario_id') ?? 0,
            $request->int('beneficio_id') ?? 0
        ));
    }

    public function rhFuncionarioBeneficioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'beneficio_id' => $request->int('beneficio_id') ?? 0,
            'valor' => $request->float('valor'),
            'data_inicio' => $request->string('data_inicio') ?: null,
            'data_fim' => $request->string('data_fim') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->rh->addEmployeeBenefit($funcionarioId, $payload));
    }

    public function rhFuncionarioComponenteRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->removeEmployeeSalaryComponent(
            $request->int('funcionario_id') ?? 0,
            $request->int('componente_id') ?? 0
        ));
    }

    public function rhFuncionarioComponenteSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'componente_id' => $request->int('componente_id') ?? 0,
            'valor' => $request->float('valor') ?? 0,
        ];

        return $d->result(fn() => $d->rh->addEmployeeSalaryComponent($funcionarioId, $payload));
    }

    public function rhFuncionarioDesligar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'data_saida' => $request->string('data_saida') ?: null,
        ];

        return $d->result(fn() => $d->rh->terminateEmployee($request->int('id') ?? 0, $payload));
    }

    public function rhFuncionarioFormacaoEditar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $registoId = $request->int('id') ?? 0;

        $payload = [
            'data_fim' => $request->string('data_fim') ?: null,
            'estado' => $request->string('estado') ?: null,
            'nota' => $request->float('nota'),
            'certificado_url' => $request->string('certificado_url') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->rh->updateEmployeeTraining($funcionarioId, $registoId, $payload));
    }

    public function rhFuncionarioFormacaoRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->removeEmployeeTraining(
            $request->int('funcionario_id') ?? 0,
            $request->int('id') ?? 0
        ));
    }

    public function rhFuncionarioFormacaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'formacao_id' => $request->int('formacao_id') ?? 0,
            'data_inicio' => $request->string('data_inicio'),
            'data_fim' => $request->string('data_fim') ?: null,
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->rh->addEmployeeTraining($funcionarioId, $payload));
    }

    public function rhFuncionarioPresencaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteAttendance(
            $request->int('funcionario_id') ?? 0,
            $request->int('presenca_id') ?? 0
        ));
    }

    public function rhFuncionarioPresencaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'data' => $request->string('data'),
            'hora_entrada' => $request->string('hora_entrada') ?: null,
            'hora_saida' => $request->string('hora_saida') ?: null,
            'horas_extra' => $request->float('horas_extra'),
            'observacoes' => $request->string('observacoes') ?: null,
        ];

        return $d->result(fn() => $d->rh->saveAttendance($funcionarioId, $payload));
    }

    public function rhFuncionarioProcessoDisciplinarEditar(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $registoId = $request->int('id') ?? 0;

        $payload = [
            'estado' => $request->string('estado') ?: null,
            'decisao' => $request->string('decisao') ?: null,
            'data_decisao' => $request->string('data_decisao') ?: null,
            'descricao' => $request->string('descricao') ?: null,
        ];

        return $d->result(fn() => $d->rh->updateEmployeeDisciplinaryProcess($funcionarioId, $registoId, $payload));
    }

    public function rhFuncionarioProcessoDisciplinarRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->removeEmployeeDisciplinaryProcess(
            $request->int('funcionario_id') ?? 0,
            $request->int('id') ?? 0
        ));
    }

    public function rhFuncionarioProcessoDisciplinarSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'tipo' => $request->string('tipo'),
            'motivo' => $request->string('motivo'),
            'descricao' => $request->string('descricao') ?: null,
            'data_ocorrencia' => $request->string('data_ocorrencia'),
        ];

        return $d->result(fn() => $d->rh->addEmployeeDisciplinaryProcess($funcionarioId, $payload));
    }

    public function rhFuncionarioSaldoAusenciaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'tipo_ausencia_id' => $request->int('tipo_ausencia_id') ?? 0,
            'ano' => $request->int('ano') ?? 0,
            'dias_atribuidos' => $request->float('dias_atribuidos'),
        ];

        return $d->result(fn() => $d->rh->setLeaveBalance($funcionarioId, $payload));
    }

    public function rhFuncionarioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = [
            'numero_funcionario' => $request->string('numero_funcionario') ?: null,
            'nome_completo' => $request->string('nome_completo'),
            'data_nascimento' => $request->string('data_nascimento') ?: null,
            'genero' => $request->string('genero') ?: null,
            'nuit' => $request->string('nuit') ?: null,
            'telefone' => $request->string('telefone') ?: null,
            'email' => $request->string('email') ?: null,
            'endereco' => $request->string('endereco') ?: null,
            'provincia' => $request->string('provincia') ?: null,
            'cidade' => $request->string('cidade') ?: null,
            'bairro' => $request->string('bairro') ?: null,
            'unit_id' => $request->int('unit_id'),
            'cargo' => $request->string('cargo') ?: null,
            'cargo_id' => $request->int('cargo_id'),
            'horario_id' => $request->int('horario_id'),
            'data_admissao' => $request->string('data_admissao') ?: null,
            'tipo_contrato' => $request->string('tipo_contrato') ?: null,
            'salario_base' => $request->float('salario_base'),
            'estado' => $request->string('estado') ?: null,
            'user_id' => $request->int('user_id'),
        ];

        return $d->result(fn() => $d->rh->saveEmployee($id, $payload));
    }

    public function rhAdiantamentoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        return $d->result(fn() => $d->rh->criarAdiantamento($funcionarioId, [
            'valor_total'    => $request->float('valor_total'),
            'num_prestacoes' => $request->int('num_prestacoes') ?? 1,
            'descricao'      => $request->string('descricao') ?: null,
            'data_inicio'    => $request->string('data_inicio') ?: null,
        ]));
    }

    public function rhAdiantamentoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->cancelarAdiantamento($request->int('id') ?? 0));
    }

    public function rhEmprestimoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        return $d->result(fn() => $d->rh->criarEmprestimo($funcionarioId, [
            'valor_total'    => $request->float('valor_total'),
            'num_prestacoes' => $request->int('num_prestacoes') ?? 1,
            'taxa_juros'     => $request->float('taxa_juros') ?? 0.0,
            'descricao'      => $request->string('descricao') ?: null,
            'data_inicio'    => $request->string('data_inicio') ?: null,
        ]));
    }

    public function rhEmprestimoCancelar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->cancelarEmprestimo($request->int('id') ?? 0));
    }

    public function rhHistoricoSalarialSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $funcionarioId = $request->int('funcionario_id') ?? 0;
        $payload = [
            'salario_novo' => $request->float('salario_novo'),
            'data_efectiva' => $request->string('data_efectiva'),
            'motivo' => $request->string('motivo') ?: null,
        ];

        return $d->result(fn() => $d->rh->createSalaryChange($funcionarioId, $payload));
    }

    public function rhHorarioRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteSchedule($request->int('id') ?? 0));
    }

    public function rhHorarioSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'hora_entrada' => $request->string('hora_entrada') ?: null,
                'hora_saida' => $request->string('hora_saida') ?: null,
                'intervalo_inicio' => $request->string('intervalo_inicio') ?: null,
                'intervalo_fim' => $request->string('intervalo_fim') ?: null,
                'dias_semana' => $request->string('dias_semana') ?: null,
                'carga_semanal_horas' => $request->float('carga_semanal_horas'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'descricao' => $request->string('descricao') ?: null,
                'hora_entrada' => $request->string('hora_entrada'),
                'hora_saida' => $request->string('hora_saida'),
                'intervalo_inicio' => $request->string('intervalo_inicio') ?: null,
                'intervalo_fim' => $request->string('intervalo_fim') ?: null,
                'dias_semana' => $request->string('dias_semana') ?: null,
                'carga_semanal_horas' => $request->float('carga_semanal_horas'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveSchedule($id, $payload));
    }

    public function rhPeriodoEncerrar(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->closePeriod($request->int('id') ?? 0));
    }

    public function rhPeriodoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $payload = [
            'nome' => $request->string('nome'),
            'data_inicio' => $request->string('data_inicio'),
            'data_fim' => $request->string('data_fim'),
        ];

        return $d->result(fn() => $d->rh->createPeriod($payload));
    }

    public function rhTipoAusenciaRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteLeaveType($request->int('id') ?? 0));
    }

    public function rhTipoAusenciaSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'dias_anuais' => $request->float('dias_anuais'),
                'remunerada' => $request->bool('remunerada'),
                'afeta_saldo' => $request->bool('afeta_saldo'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'dias_anuais' => $request->float('dias_anuais'),
                'remunerada' => $request->bool('remunerada'),
                'afeta_saldo' => $request->bool('afeta_saldo'),
            ];

        if ($request->has('ativo')) {
            $payload['ativo'] = $request->bool('ativo');
        }

        return $d->result(fn() => $d->rh->saveLeaveType($id, $payload));
    }

    public function rhUnidadeMover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(
            fn() => $d->rh->moveUnit(
                $request->int('id') ?? 0,
                $request->int('parent_id')
            )
        );
    }

    public function rhUnidadeRemover(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->deleteUnit($request->int('id') ?? 0));
    }

    public function rhUnidadeSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        $id = $request->int('id');

        $payload = $id
            ? [
                'codigo' => $request->string('codigo') ?: null,
                'nome' => $request->string('nome') ?: null,
                'tipo' => $request->string('tipo') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'responsavel_id' => $request->int('responsavel_id'),
                'parent_id' => $request->int('parent_id'),
                'ativo' => $request->bool('ativo'),
            ]
            : [
                'codigo' => $request->string('codigo'),
                'nome' => $request->string('nome'),
                'tipo' => $request->string('tipo') ?: null,
                'descricao' => $request->string('descricao') ?: null,
                'responsavel_id' => $request->int('responsavel_id'),
                'parent_id' => $request->int('parent_id'),
            ];

        return $d->result(fn() => $d->rh->saveUnit($id, $payload));
    }

    public function rhProximoNumeroFuncionario(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->getProximoNumero());
    }

    public function rhIrpsEscaloes(Request $request, AdminApiDependencies $d): ApiResult
    {
        $ano = $request->int('ano');
        return $d->result(fn() => $d->rh->listarIrpsEscaloes($ano));
    }

    public function rhIrpsEscalaoSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->criarIrpsEscalao([
            'ano_fiscal'  => $request->int('ano_fiscal') ?? (int)date('Y'),
            'limite_inf'  => $request->float('limite_inf') ?? 0,
            'limite_sup'  => $request->float('limite_sup'),
            'taxa'        => $request->float('taxa') ?? 0,
            'parcela_ded' => $request->float('parcela_ded') ?? 0,
        ]));
    }

    public function rhIrpsEscalaoUpdate(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->actualizarIrpsEscalao($request->int('id') ?? 0, [
            'limite_sup'  => $request->float('limite_sup'),
            'taxa'        => $request->float('taxa') ?? 0,
            'parcela_ded' => $request->float('parcela_ded') ?? 0,
            'ativo'       => $request->has('ativo') ? $request->bool('ativo') : null,
        ]));
    }

    public function rhIrpsEscalaoDelete(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->eliminarIrpsEscalao($request->int('id') ?? 0));
    }

    public function rhIrpsSeedMozambique(Request $_, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->seedIrpsMozambique2024());
    }

    public function rhConfigSave(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(fn() => $d->rh->saveConfig(
            $request->string('chave') ?? '',
            $request->string('valor') ?: null,
        ));
    }

    public function rhOperacao(Request $request, AdminApiDependencies $d): ApiResult
    {
        $operation = $request->string('operation');
        $id        = $request->int('id');
        $payload   = (array) ($request->all()['payload'] ?? []);

        return match ($operation) {
            // ── Cargos ────────────────────────────────────────────────────────
            'cargo.create' => $d->result(fn() => $d->rh->savePosition(null, $payload)),
            'cargo.update' => $d->result(fn() => $d->rh->savePosition($id, $payload)),
            'cargo.delete' => $d->result(fn() => $d->rh->deletePosition($id ?? 0)),
            // ── Unidades Organizacionais ───────────────────────────────────────
            'unidade.create' => $d->result(fn() => $d->rh->saveUnit(null, $payload)),
            'unidade.update' => $d->result(fn() => $d->rh->saveUnit($id, $payload)),
            'unidade.delete' => $d->result(fn() => $d->rh->deleteUnit($id ?? 0)),
            'unidade.mover'  => $d->result(fn() => $d->rh->moveUnit(
                $id ?? 0,
                isset($payload['parent_id']) && $payload['parent_id'] !== '' ? (int) $payload['parent_id'] : null
            )),
            // ── Horários de Trabalho ───────────────────────────────────────────
            'horario.create' => $d->result(fn() => $d->rh->saveSchedule(null, $payload)),
            'horario.update' => $d->result(fn() => $d->rh->saveSchedule($id, $payload)),
            'horario.delete' => $d->result(fn() => $d->rh->deleteSchedule($id ?? 0)),
            // ── Componentes Salariais ──────────────────────────────────────────
            'componente.create' => $d->result(fn() => $d->rh->saveSalaryComponent(null, $payload)),
            'componente.update' => $d->result(fn() => $d->rh->saveSalaryComponent($id, $payload)),
            'componente.delete' => $d->result(fn() => $d->rh->deleteSalaryComponent($id ?? 0)),
            // ── Benefícios ────────────────────────────────────────────────────
            'beneficio.create' => $d->result(fn() => $d->rh->saveBenefit(null, $payload)),
            'beneficio.update' => $d->result(fn() => $d->rh->saveBenefit($id, $payload)),
            'beneficio.delete' => $d->result(fn() => $d->rh->deleteBenefit($id ?? 0)),
            // ── Tipos de Ausência ─────────────────────────────────────────────
            'tipo_ausencia.create' => $d->result(fn() => $d->rh->saveLeaveType(null, $payload)),
            'tipo_ausencia.update' => $d->result(fn() => $d->rh->saveLeaveType($id, $payload)),
            'tipo_ausencia.delete' => $d->result(fn() => $d->rh->deleteLeaveType($id ?? 0)),
            // ── Critérios de Avaliação ────────────────────────────────────────
            'criterio.create' => $d->result(fn() => $d->rh->saveEvaluationCriterion(null, $payload)),
            'criterio.update' => $d->result(fn() => $d->rh->saveEvaluationCriterion($id, $payload)),
            'criterio.delete' => $d->result(fn() => $d->rh->deleteEvaluationCriterion($id ?? 0)),
            // ── Formações ─────────────────────────────────────────────────────
            'formacao.create' => $d->result(fn() => $d->rh->saveTraining(null, $payload)),
            'formacao.update' => $d->result(fn() => $d->rh->saveTraining($id, $payload)),
            'formacao.delete' => $d->result(fn() => $d->rh->deleteTraining($id ?? 0)),
            // ── Períodos de Avaliação ─────────────────────────────────────────
            'periodo.create'   => $d->result(fn() => $d->rh->createPeriod($payload)),
            'periodo.encerrar' => $d->result(fn() => $d->rh->closePeriod($id ?? 0)),
            // ── Processamento Salarial ────────────────────────────────────────
            'folha.create'    => $d->result(fn() => $d->rh->createPayrollRun($payload)),
            'folha.processar' => $d->result(fn() => $d->rh->processPayrollRun($id ?? 0)),
            'folha.pagar'     => $d->result(fn() => $d->rh->payPayrollRun($id ?? 0, $payload)),
            'folha.cancelar'  => $d->result(fn() => $d->rh->cancelPayrollRun($id ?? 0)),
            default => new ApiResult(['erro' => "Operação RH desconhecida: $operation"], 400),
        };
    }

    public function rhContratoEnviarAssinatura(Request $request, AdminApiDependencies $d): ApiResult
    {
        return $d->result(function () use ($d, $request): array {
            $contractId = $request->int('id') ?? 0;
            if ($contractId <= 0) {
                throw new OperationException('Contrato inválido.');
            }

            $contract = $d->rh->getContract($contractId);
            $employeeId = (int) ($contract['funcionario_id'] ?? 0);
            if ($employeeId <= 0) {
                throw new OperationException('Funcionário do contrato não encontrado.');
            }

            $pdf = $d->rh->downloadContractPdf($contractId);
            if (($pdf['status'] ?? 0) !== 200 || empty($pdf['body'])) {
                throw new OperationException('PDF do contrato não encontrado. Gere o PDF primeiro.');
            }

            $tmpPath = tempnam(sys_get_temp_dir(), 'contrato_') . '.pdf';
            file_put_contents($tmpPath, $pdf['body']);

            $employee = $d->rh->getEmployee($employeeId);
            $dadosFunc = $employee['funcionario'] ?? $employee;
            $nome = $dadosFunc['nome_completo'] ?? ($dadosFunc['nome'] ?? 'Funcionário');
            $email = $dadosFunc['email'] ?? null;

            try {
                $doc = $d->assinaturaDigital->uploadDocumento(
                    'Contrato de trabalho — ' . $nome,
                    'Contrato gerado automaticamente a partir do RH.',
                    ['tmp_name' => $tmpPath, 'name' => "contrato-$contractId.pdf", 'type' => 'application/pdf']
                );

                $docId = (int) ($doc['id'] ?? 0);
                if ($docId > 0) {
                    $d->assinaturaDigital->adicionarSignatario($docId, [
                        'nome' => $nome,
                        'email' => $email,
                        'ordem' => 1,
                        'pagina' => 1,
                        'x' => 100,
                        'y' => 100,
                    ]);
                }

                return ['ok' => true, 'doc_id' => $docId];
            } finally {
                if (file_exists($tmpPath)) {
                    unlink($tmpPath);
                }
            }
        });
    }
}
