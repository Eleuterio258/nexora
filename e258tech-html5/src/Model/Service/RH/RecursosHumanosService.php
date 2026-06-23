<?php
declare (strict_types = 1);

namespace E258Tech\Model\Service\RH;

use E258Tech\Model\Contract\NexoraGateway;
use E258Tech\Model\Exception\OperationException;
use E258Tech\Model\Service\NexoraService;

final class RecursosHumanosService extends NexoraService
{
    public function __construct(private readonly NexoraGateway $gateway)
    {
    }

    public function saveUnit(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome da unidade organizacional são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/unidades/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/unidades', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a unidade organizacional.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Unidade organizacional actualizada com sucesso.' : 'Unidade organizacional criada com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteUnit(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Unidade organizacional invalida.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/unidades/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a unidade organizacional.');

        return ['ok' => true, 'msg' => 'Unidade organizacional eliminada com sucesso.'];
    }

    public function moveUnit(int $id, ?int $parentId): array
    {
        if ($id <= 0) {
            throw new OperationException('Unidade organizacional invalida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/unidades/$id/mover", ['parent_id' => $parentId]);
        $this->ensureSuccess($response, 'Erro ao mover a unidade organizacional.');

        return ['ok' => true, 'msg' => 'Unidade organizacional movida com sucesso.'];
    }

    public function saveEmployee(?int $id, array $payload): array
    {
        if (! $id && ($payload['nome_completo'] ?? '') === '') {
            throw new OperationException('O nome completo do funcionario e obrigatorio.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/funcionarios/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/funcionarios', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o funcionario.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Funcionario actualizado com sucesso.' : 'Funcionario criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function terminateEmployee(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Funcionario invalido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$id/desligar", $payload);
        $this->ensureSuccess($response, 'Erro ao desligar o funcionario.');

        return ['ok' => true, 'msg' => 'Funcionario desligado com sucesso.'];
    }

    public function createContract(array $payload): array
    {
        if (($payload['funcionario_id'] ?? 0) <= 0) {
            throw new OperationException('O funcionario e obrigatorio.');
        }
        if (($payload['tipo'] ?? '') === '') {
            throw new OperationException('O tipo de contrato e obrigatorio.');
        }
        if (($payload['data_inicio'] ?? '') === '') {
            throw new OperationException('A data de inicio do contrato e obrigatoria.');
        }

        $response = $this->gateway->request('POST', '/api/rh/contratos', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o contrato.');

        return ['ok' => true, 'msg' => 'Contrato criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function updateContract(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Contrato inválido.');
        }

        $response = $this->gateway->request('PUT', "/api/rh/contratos/$id", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o contrato.');

        return ['ok' => true, 'msg' => 'Contrato actualizado com sucesso.', 'id' => $id];
    }

    public function renewContract(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Contrato inválido.');
        }
        if (($payload['data_fim'] ?? '') === '') {
            throw new OperationException('A nova data de fim do contrato é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/rh/contratos/$id/renovar", $payload);
        $this->ensureSuccess($response, 'Erro ao renovar o contrato.');

        return ['ok' => true, 'msg' => 'Contrato renovado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function terminateContract(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Contrato inválido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/contratos/$id/rescindir", $payload);
        $this->ensureSuccess($response, 'Erro ao rescindir o contrato.');

        return ['ok' => true, 'msg' => 'Contrato rescindido com sucesso.'];
    }

    public function listSalaryHistory(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/historico-salarial");
        $this->ensureSuccess($response, 'Erro ao obter o histórico salarial.');

        return $response->body ?? [];
    }

    public function createSalaryChange(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['salario_novo'] ?? 0) <= 0) {
            throw new OperationException('O novo salário é obrigatório.');
        }
        if (($payload['data_efectiva'] ?? '') === '') {
            throw new OperationException('A data de efeito é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/historico-salarial", $payload);
        $this->ensureSuccess($response, 'Erro ao registar a alteração salarial.');

        return ['ok' => true, 'msg' => 'Alteração salarial registada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function listSalaryComponents(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/componentes-salariais');
        $this->ensureSuccess($response, 'Erro ao obter os componentes salariais.');

        return $response->body ?? [];
    }

    public function saveSalaryComponent(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do componente salarial são obrigatórios.');
        }
        if (! $id && ($payload['tipo'] ?? '') === '') {
            throw new OperationException('O tipo do componente salarial é obrigatório.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/componentes-salariais/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/componentes-salariais', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o componente salarial.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Componente salarial actualizado com sucesso.' : 'Componente salarial criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteSalaryComponent(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Componente salarial inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/componentes-salariais/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o componente salarial.');

        return ['ok' => true, 'msg' => 'Componente salarial eliminado com sucesso.'];
    }

    public function listEmployeeSalaryComponents(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/componentes-salariais");
        $this->ensureSuccess($response, 'Erro ao obter os componentes salariais do funcionário.');

        return $response->body ?? [];
    }

    public function addEmployeeSalaryComponent(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['componente_id'] ?? 0) <= 0) {
            throw new OperationException('O componente salarial é obrigatório.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/componentes-salariais", $payload);
        $this->ensureSuccess($response, 'Erro ao atribuir o componente salarial.');

        return ['ok' => true, 'msg' => 'Componente salarial atribuído com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function removeEmployeeSalaryComponent(int $funcionarioId, int $componenteId): array
    {
        if ($funcionarioId <= 0 || $componenteId <= 0) {
            throw new OperationException('Componente salarial inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/funcionarios/$funcionarioId/componentes-salariais/$componenteId");
        $this->ensureSuccess($response, 'Erro ao remover o componente salarial.');

        return ['ok' => true, 'msg' => 'Componente salarial removido com sucesso.'];
    }

    public function listBenefits(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/beneficios');
        $this->ensureSuccess($response, 'Erro ao obter os benefícios.');

        return $response->body ?? [];
    }

    public function saveBenefit(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do benefício são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/beneficios/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/beneficios', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o benefício.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Benefício actualizado com sucesso.' : 'Benefício criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteBenefit(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Benefício inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/beneficios/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o benefício.');

        return ['ok' => true, 'msg' => 'Benefício eliminado com sucesso.'];
    }

    public function listEmployeeBenefits(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/beneficios");
        $this->ensureSuccess($response, 'Erro ao obter os benefícios do funcionário.');

        return $response->body ?? [];
    }

    public function addEmployeeBenefit(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['beneficio_id'] ?? 0) <= 0) {
            throw new OperationException('O benefício é obrigatório.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/beneficios", $payload);
        $this->ensureSuccess($response, 'Erro ao atribuir o benefício.');

        return ['ok' => true, 'msg' => 'Benefício atribuído com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function removeEmployeeBenefit(int $funcionarioId, int $beneficioId): array
    {
        if ($funcionarioId <= 0 || $beneficioId <= 0) {
            throw new OperationException('Benefício inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/funcionarios/$funcionarioId/beneficios/$beneficioId");
        $this->ensureSuccess($response, 'Erro ao remover o benefício.');

        return ['ok' => true, 'msg' => 'Benefício removido com sucesso.'];
    }

    public function listAttendance(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/presencas");
        $this->ensureSuccess($response, 'Erro ao obter as presenças do funcionário.');

        return $response->body ?? [];
    }

    public function saveAttendance(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['data'] ?? '') === '') {
            throw new OperationException('A data é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/presencas", $payload);
        $this->ensureSuccess($response, 'Erro ao registar a presença.');

        return ['ok' => true, 'msg' => 'Presença registada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function deleteAttendance(int $funcionarioId, int $presencaId): array
    {
        if ($funcionarioId <= 0 || $presencaId <= 0) {
            throw new OperationException('Registo de presença inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/funcionarios/$funcionarioId/presencas/$presencaId");
        $this->ensureSuccess($response, 'Erro ao remover o registo de presença.');

        return ['ok' => true, 'msg' => 'Registo de presença removido com sucesso.'];
    }

    public function createLeaveRequest(array $payload): array
    {
        if (($payload['funcionario_id'] ?? 0) <= 0) {
            throw new OperationException('O funcionario e obrigatorio.');
        }
        if (($payload['tipo_id'] ?? 0) <= 0) {
            throw new OperationException('O tipo de ausencia e obrigatorio.');
        }
        if (($payload['data_inicio'] ?? '') === '' || ($payload['data_fim'] ?? '') === '') {
            throw new OperationException('As datas de inicio e fim sao obrigatorias.');
        }

        $response = $this->gateway->request('POST', '/api/rh/ausencias', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o pedido de ausencia.');

        return ['ok' => true, 'msg' => 'Pedido de ausencia criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function approveLeave(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido de ausencia invalido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/ausencias/$id/aprovar");
        $this->ensureSuccess($response, 'Erro ao aprovar o pedido de ausencia.');

        return ['ok' => true, 'msg' => 'Pedido de ausencia aprovado.'];
    }

    public function rejectLeave(int $id, array $payload): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido de ausencia invalido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/ausencias/$id/rejeitar", $payload);
        $this->ensureSuccess($response, 'Erro ao rejeitar o pedido de ausencia.');

        return ['ok' => true, 'msg' => 'Pedido de ausencia rejeitado.'];
    }

    public function markLeaveTaken(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido de ausencia invalido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/ausencias/$id/gozar");
        $this->ensureSuccess($response, 'Erro ao marcar o pedido de ausencia como gozado.');

        return ['ok' => true, 'msg' => 'Pedido de ausencia marcado como gozado.'];
    }

    public function cancelLeave(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido de ausencia invalido.');
        }

        $response = $this->gateway->request('POST', "/api/rh/ausencias/$id/cancelar");
        $this->ensureSuccess($response, 'Erro ao cancelar o pedido de ausencia.');

        return ['ok' => true, 'msg' => 'Pedido de ausencia cancelado.'];
    }

    // ── Self-service: pedido de férias ───────────────────────────────────────

    public function criarPedidoFerias(array $payload): array
    {
        if (($payload['tipo_id'] ?? 0) <= 0) {
            throw new OperationException('O tipo de ausência é obrigatório.');
        }
        if (($payload['data_inicio'] ?? '') === '' || ($payload['data_fim'] ?? '') === '') {
            throw new OperationException('As datas de início e fim são obrigatórias.');
        }

        $response = $this->gateway->request('POST', '/api/pedido-ferias/', $payload);
        $this->ensureSuccess($response, 'Erro ao submeter o pedido de férias.');

        return ['ok' => true, 'msg' => 'Pedido submetido com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function cancelarPedidoFerias(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Pedido inválido.');
        }

        $response = $this->gateway->request('POST', "/api/pedido-ferias/$id/cancelar");
        $this->ensureSuccess($response, 'Erro ao cancelar o pedido de férias.');

        return ['ok' => true, 'msg' => 'Pedido cancelado.'];
    }

    public function listLeaveTypes(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/tipos-ausencia');
        $this->ensureSuccess($response, 'Erro ao obter os tipos de ausência.');

        return $response->body ?? [];
    }

    public function saveLeaveType(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do tipo de ausência são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/tipos-ausencia/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/tipos-ausencia', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o tipo de ausência.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Tipo de ausência actualizado com sucesso.' : 'Tipo de ausência criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteLeaveType(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Tipo de ausência inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/tipos-ausencia/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o tipo de ausência.');

        return ['ok' => true, 'msg' => 'Tipo de ausência eliminado com sucesso.'];
    }

    public function listLeaveBalances(int $funcionarioId, ?int $ano = null): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $path = "/api/rh/funcionarios/$funcionarioId/saldos-ausencia";
        if ($ano !== null) {
            $path .= '?ano=' . $ano;
        }

        $response = $this->gateway->request('GET', $path);
        $this->ensureSuccess($response, 'Erro ao obter os saldos de férias/licenças.');

        return $response->body ?? [];
    }

    public function setLeaveBalance(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['tipo_ausencia_id'] ?? 0) <= 0) {
            throw new OperationException('O tipo de ausência é obrigatório.');
        }
        if (($payload['ano'] ?? 0) <= 0) {
            throw new OperationException('O ano é obrigatório.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/saldos-ausencia", $payload);
        $this->ensureSuccess($response, 'Erro ao definir o saldo de férias/licenças.');

        return ['ok' => true, 'msg' => 'Saldo de férias/licenças actualizado com sucesso.'];
    }

    public function createEvaluation(array $payload): array
    {
        if (($payload['funcionario_id'] ?? 0) <= 0) {
            throw new OperationException('O funcionario e obrigatorio.');
        }
        if (($payload['periodo_id'] ?? 0) <= 0) {
            throw new OperationException('O periodo da avaliacao e obrigatorio.');
        }
        if (empty($payload['criterios'])) {
            throw new OperationException('A avaliação deve ter pelo menos um critério pontuado.');
        }

        $response = $this->gateway->request('POST', '/api/rh/avaliacoes', $payload);
        $this->ensureSuccess($response, 'Erro ao registar a avaliacao.');

        return ['ok' => true, 'msg' => 'Avaliacao registada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function submitEvaluation(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Avaliação inválida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/avaliacoes/$id/submeter");
        $this->ensureSuccess($response, 'Erro ao submeter a avaliação.');

        return ['ok' => true, 'msg' => 'Avaliação submetida com sucesso.'];
    }

    public function approveEvaluation(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Avaliação inválida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/avaliacoes/$id/aprovar");
        $this->ensureSuccess($response, 'Erro ao aprovar a avaliação.');

        return ['ok' => true, 'msg' => 'Avaliação aprovada com sucesso.'];
    }

    public function listEvaluationCriteria(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/criterios-avaliacao');
        $this->ensureSuccess($response, 'Erro ao obter os critérios de avaliação.');

        return $response->body ?? [];
    }

    public function saveEvaluationCriterion(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do critério são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/criterios-avaliacao/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/criterios-avaliacao', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o critério de avaliação.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Critério de avaliação actualizado com sucesso.' : 'Critério de avaliação criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteEvaluationCriterion(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Critério de avaliação inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/criterios-avaliacao/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o critério de avaliação.');

        return ['ok' => true, 'msg' => 'Critério de avaliação eliminado com sucesso.'];
    }

    public function listPeriods(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/periodos');
        $this->ensureSuccess($response, 'Erro ao obter os periodos de avaliacao.');

        return $response->body ?? [];
    }

    public function createPeriod(array $payload): array
    {
        if (($payload['nome'] ?? '') === '') {
            throw new OperationException('O nome do periodo e obrigatorio.');
        }
        if (($payload['data_inicio'] ?? '') === '' || ($payload['data_fim'] ?? '') === '') {
            throw new OperationException('As datas de inicio e fim sao obrigatorias.');
        }

        $response = $this->gateway->request('POST', '/api/rh/periodos', $payload);
        $this->ensureSuccess($response, 'Erro ao criar o periodo de avaliacao.');

        return ['ok' => true, 'msg' => 'Periodo de avaliacao criado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function closePeriod(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Periodo de avaliacao invalido.');
        }

        $response = $this->gateway->request('PUT', "/api/rh/periodos/$id", ['estado' => 'encerrado']);
        $this->ensureSuccess($response, 'Erro ao encerrar o periodo de avaliacao.');

        return ['ok' => true, 'msg' => 'Periodo de avaliacao encerrado.'];
    }

    public function listPositions(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/cargos');
        $this->ensureSuccess($response, 'Erro ao obter os cargos.');

        return $response->body ?? [];
    }

    public function savePosition(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do cargo são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/cargos/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/cargos', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o cargo.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Cargo actualizado com sucesso.' : 'Cargo criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deletePosition(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Cargo invalido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/cargos/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o cargo.');

        return ['ok' => true, 'msg' => 'Cargo eliminado com sucesso.'];
    }

    public function listSchedules(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/horarios');
        $this->ensureSuccess($response, 'Erro ao obter os horários de trabalho.');

        return $response->body ?? [];
    }

    public function saveSchedule(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome do horário são obrigatórios.');
        }

        if (! $id && (($payload['hora_entrada'] ?? '') === '' || ($payload['hora_saida'] ?? '') === '')) {
            throw new OperationException('A hora de entrada e a hora de saída são obrigatórias.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/horarios/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/horarios', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar o horário de trabalho.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Horário actualizado com sucesso.' : 'Horário criado com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteSchedule(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Horário inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/horarios/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o horário de trabalho.');

        return ['ok' => true, 'msg' => 'Horário eliminado com sucesso.'];
    }

    public function createEmergencyContact(array $payload): array
    {
        if (($payload['funcionario_id'] ?? 0) <= 0) {
            throw new OperationException('O funcionário é obrigatório.');
        }
        if (($payload['nome'] ?? '') === '' || ($payload['telefone'] ?? '') === '') {
            throw new OperationException('O nome e o telefone do contacto são obrigatórios.');
        }

        $response = $this->gateway->request('POST', '/api/rh/contactos-emergencia', $payload);
        $this->ensureSuccess($response, 'Erro ao guardar o contacto de emergência.');

        return ['ok' => true, 'msg' => 'Contacto de emergência guardado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function deleteEmergencyContact(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Contacto de emergência inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/contactos-emergencia/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o contacto de emergência.');

        return ['ok' => true, 'msg' => 'Contacto de emergência eliminado com sucesso.'];
    }

    public function createDocument(array $payload): array
    {
        if (($payload['funcionario_id'] ?? 0) <= 0) {
            throw new OperationException('O funcionário é obrigatório.');
        }
        if (($payload['tipo'] ?? '') === '') {
            throw new OperationException('O tipo de documento é obrigatório.');
        }

        $response = $this->gateway->request('POST', '/api/rh/documentos', $payload);
        $this->ensureSuccess($response, 'Erro ao guardar o documento.');

        return ['ok' => true, 'msg' => 'Documento guardado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function deleteDocument(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Documento inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/documentos/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar o documento.');

        return ['ok' => true, 'msg' => 'Documento eliminado com sucesso.', 'ficheiro_url' => $response->body['ficheiro_url'] ?? null];
    }

    public function listTrainings(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/formacoes');
        $this->ensureSuccess($response, 'Erro ao obter as formações.');

        return $response->body ?? [];
    }

    public function saveTraining(?int $id, array $payload): array
    {
        if (! $id && (($payload['codigo'] ?? '') === '' || ($payload['nome'] ?? '') === '')) {
            throw new OperationException('O código e o nome da formação são obrigatórios.');
        }

        $response = $id
            ? $this->gateway->request('PUT', "/api/rh/formacoes/$id", $payload)
            : $this->gateway->request('POST', '/api/rh/formacoes', $payload);

        $this->ensureSuccess($response, 'Erro ao guardar a formação.');

        return [
            'ok'  => true,
            'msg' => $id ? 'Formação actualizada com sucesso.' : 'Formação criada com sucesso.',
            'id'  => $response->body['id'] ?? $id,
        ];
    }

    public function deleteTraining(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Formação inválida.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/formacoes/$id");
        $this->ensureSuccess($response, 'Erro ao eliminar a formação.');

        return ['ok' => true, 'msg' => 'Formação eliminada com sucesso.'];
    }

    public function listEmployeeTrainings(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/formacoes");
        $this->ensureSuccess($response, 'Erro ao obter as formações do funcionário.');

        return $response->body ?? [];
    }

    public function addEmployeeTraining(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['formacao_id'] ?? 0) <= 0) {
            throw new OperationException('A formação é obrigatória.');
        }
        if (($payload['data_inicio'] ?? '') === '') {
            throw new OperationException('A data de início é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/formacoes", $payload);
        $this->ensureSuccess($response, 'Erro ao registar a formação.');

        return ['ok' => true, 'msg' => 'Formação registada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function updateEmployeeTraining(int $funcionarioId, int $registoId, array $payload): array
    {
        if ($funcionarioId <= 0 || $registoId <= 0) {
            throw new OperationException('Registo de formação inválido.');
        }

        $response = $this->gateway->request('PUT', "/api/rh/funcionarios/$funcionarioId/formacoes/$registoId", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar a formação.');

        return ['ok' => true, 'msg' => 'Formação actualizada com sucesso.'];
    }

    public function removeEmployeeTraining(int $funcionarioId, int $registoId): array
    {
        if ($funcionarioId <= 0 || $registoId <= 0) {
            throw new OperationException('Registo de formação inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/funcionarios/$funcionarioId/formacoes/$registoId");
        $this->ensureSuccess($response, 'Erro ao remover a formação.');

        return ['ok' => true, 'msg' => 'Formação removida com sucesso.'];
    }

    public function listEmployeeDisciplinaryProcesses(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/processos-disciplinares");
        $this->ensureSuccess($response, 'Erro ao obter os processos disciplinares do funcionário.');

        return $response->body ?? [];
    }

    public function addEmployeeDisciplinaryProcess(int $funcionarioId, array $payload): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }
        if (($payload['tipo'] ?? '') === '') {
            throw new OperationException('O tipo de processo disciplinar é obrigatório.');
        }
        if (($payload['motivo'] ?? '') === '') {
            throw new OperationException('O motivo é obrigatório.');
        }
        if (($payload['data_ocorrencia'] ?? '') === '') {
            throw new OperationException('A data de ocorrência é obrigatória.');
        }

        $response = $this->gateway->request('POST', "/api/rh/funcionarios/$funcionarioId/processos-disciplinares", $payload);
        $this->ensureSuccess($response, 'Erro ao registar o processo disciplinar.');

        return ['ok' => true, 'msg' => 'Processo disciplinar registado com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function updateEmployeeDisciplinaryProcess(int $funcionarioId, int $registoId, array $payload): array
    {
        if ($funcionarioId <= 0 || $registoId <= 0) {
            throw new OperationException('Processo disciplinar inválido.');
        }
        if (($payload['estado'] ?? '') === 'decidido' && (($payload['decisao'] ?? '') === '' || ($payload['data_decisao'] ?? '') === '')) {
            throw new OperationException('A decisão e a data de decisão são obrigatórias para decidir o processo.');
        }

        $response = $this->gateway->request('PUT', "/api/rh/funcionarios/$funcionarioId/processos-disciplinares/$registoId", $payload);
        $this->ensureSuccess($response, 'Erro ao actualizar o processo disciplinar.');

        return ['ok' => true, 'msg' => 'Processo disciplinar actualizado com sucesso.'];
    }

    public function removeEmployeeDisciplinaryProcess(int $funcionarioId, int $registoId): array
    {
        if ($funcionarioId <= 0 || $registoId <= 0) {
            throw new OperationException('Processo disciplinar inválido.');
        }

        $response = $this->gateway->request('DELETE', "/api/rh/funcionarios/$funcionarioId/processos-disciplinares/$registoId");
        $this->ensureSuccess($response, 'Erro ao remover o processo disciplinar.');

        return ['ok' => true, 'msg' => 'Processo disciplinar removido com sucesso.'];
    }

    // ── Processamento Salarial ───────────────────────────────────────────────

    public function listPayrollRuns(): array
    {
        $response = $this->gateway->request('GET', '/api/rh/folhas-pagamento');
        $this->ensureSuccess($response, 'Erro ao obter as folhas de pagamento.');

        return $response->body ?? [];
    }

    public function getPayrollRun(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Folha de pagamento inválida.');
        }

        $response = $this->gateway->request('GET', "/api/rh/folhas-pagamento/$id");
        $this->ensureSuccess($response, 'Erro ao obter a folha de pagamento.');

        return $response->body ?? [];
    }

    public function createPayrollRun(array $payload): array
    {
        if ((int) ($payload['ano'] ?? 0) <= 0 || (int) ($payload['mes'] ?? 0) <= 0) {
            throw new OperationException('O ano e o mês são obrigatórios.');
        }

        $response = $this->gateway->request('POST', '/api/rh/folhas-pagamento', $payload);
        $this->ensureSuccess($response, 'Erro ao criar a folha de pagamento.');

        return ['ok' => true, 'msg' => 'Folha de pagamento criada com sucesso.', 'id' => $response->body['id'] ?? null];
    }

    public function processPayrollRun(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Folha de pagamento inválida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/folhas-pagamento/$id/processar");
        $this->ensureSuccess($response, 'Erro ao processar a folha de pagamento.');

        return ['ok' => true, 'msg' => 'Folha de pagamento processada com sucesso.'];
    }

    public function payPayrollRun(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Folha de pagamento inválida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/folhas-pagamento/$id/pagar");
        $this->ensureSuccess($response, 'Erro ao marcar a folha de pagamento como paga.');

        return ['ok' => true, 'msg' => 'Folha de pagamento marcada como paga.'];
    }

    public function cancelPayrollRun(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Folha de pagamento inválida.');
        }

        $response = $this->gateway->request('POST', "/api/rh/folhas-pagamento/$id/cancelar");
        $this->ensureSuccess($response, 'Erro ao cancelar a folha de pagamento.');

        return ['ok' => true, 'msg' => 'Folha de pagamento cancelada.'];
    }

    public function listEmployeePayslips(int $funcionarioId): array
    {
        if ($funcionarioId <= 0) {
            throw new OperationException('Funcionário inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/funcionarios/$funcionarioId/recibos-vencimento");
        $this->ensureSuccess($response, 'Erro ao obter os recibos de vencimento do funcionário.');

        return $response->body ?? [];
    }

    public function getPayslip(int $id): array
    {
        if ($id <= 0) {
            throw new OperationException('Recibo de vencimento inválido.');
        }

        $response = $this->gateway->request('GET', "/api/rh/recibos-vencimento/$id");
        $this->ensureSuccess($response, 'Erro ao obter o recibo de vencimento.');

        return $response->body ?? [];
    }
}
