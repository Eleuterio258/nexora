<?php
declare(strict_types=1);

namespace E258Tech\Model\Service\School;

use E258Tech\Model\Service\OperationalModuleService;

final class SchoolService extends OperationalModuleService
{
    protected function operations(): array
    {
        return [
            'year.view' => $this->op('GET', '/api/escolar/years/{id}'),
            'year.create' => $this->op('POST', '/api/escolar/years'),
            'year.update' => $this->op('PUT', '/api/escolar/years/{id}'),
            'year.activate' => $this->op('POST', '/api/escolar/years/{id}/activar'),
            'year.close' => $this->op('POST', '/api/escolar/years/{id}/close'),
            'term.create' => $this->op('POST', '/api/escolar/years/{id}/terms'),
            'term.update' => $this->op('PUT', '/api/escolar/terms/{id}'),
            'term.delete' => $this->op('DELETE', '/api/escolar/terms/{id}'),
            'class.view' => $this->op('GET', '/api/escolar/classes/{id}'),
            'class.create' => $this->op('POST', '/api/escolar/classes'),
            'class.update' => $this->op('PUT', '/api/escolar/classes/{id}'),
            'class.teacher' => $this->op('POST', '/api/escolar/classes/{id}/assign-teacher'),
            'subject.create' => $this->op('POST', '/api/escolar/subjects'),
            'teacher.assignment.create' => $this->op('POST', '/api/escolar/teacher-assignments'),
            'teacher.view' => $this->op('GET', '/api/escolar/teachers/{id}'),
            'teacher.list' => $this->op('GET', '/api/escolar/teachers'),
            'teacher.create' => $this->op('POST', '/api/escolar/teachers'),
            'teacher.update' => $this->op('PUT', '/api/escolar/teachers/{id}'),
            'teacher.delete' => $this->op('DELETE', '/api/escolar/teachers/{id}'),
            'level.view' => $this->op('GET', '/api/escolar/levels/{id}'),
            'level.list' => $this->op('GET', '/api/escolar/levels'),
            'level.create' => $this->op('POST', '/api/escolar/levels'),
            'level.update' => $this->op('PUT', '/api/escolar/levels/{id}'),
            'level.delete' => $this->op('DELETE', '/api/escolar/levels/{id}'),
            'series.view' => $this->op('GET', '/api/escolar/series/{id}'),
            'series.list' => $this->op('GET', '/api/escolar/series'),
            'series.create' => $this->op('POST', '/api/escolar/series'),
            'series.update' => $this->op('PUT', '/api/escolar/series/{id}'),
            'series.delete' => $this->op('DELETE', '/api/escolar/series/{id}'),
            'course.view' => $this->op('GET', '/api/escolar/courses/{id}'),
            'course.list' => $this->op('GET', '/api/escolar/courses'),
            'course.create' => $this->op('POST', '/api/escolar/courses'),
            'course.update' => $this->op('PUT', '/api/escolar/courses/{id}'),
            'course.delete' => $this->op('DELETE', '/api/escolar/courses/{id}'),
            'student.view' => $this->op('GET', '/api/escolar/students/{id}'),
            'student.create' => $this->op('POST', '/api/escolar/students'),
            'student.update' => $this->op('PUT', '/api/escolar/students/{id}'),
            'guardian.create' => $this->op('POST', '/api/escolar/students/{id}/guardians'),
            'portal.status'      => $this->op('GET',  '/api/escolar/students/{id}/portal/status'),
            'portal.activate'    => $this->op('POST', '/api/escolar/students/{id}/portal/activate'),
            'portal.invite'      => $this->op('POST', '/api/escolar/students/{id}/portal/invite'),
            'portal.reset_senha' => $this->op('POST', '/api/escolar/students/{id}/portal/reset-senha'),
            'portal.deactivate'  => $this->op('POST', '/api/escolar/students/{id}/portal/deactivate'),
            'enrollment.view' => $this->op('GET', '/api/escolar/enrollments/{id}'),
            'enrollment.create' => $this->op('POST', '/api/escolar/enrollments'),
            'enrollment.transfer' => $this->op('POST', '/api/escolar/enrollments/{id}/transfer'),
            'enrollment.cancel' => $this->op('POST', '/api/escolar/enrollments/{id}/cancel'),
            'student.role.create' => $this->op('POST', '/api/escolar/student-roles'),
            'student.role.update' => $this->op('PUT', '/api/escolar/student-roles/{id}'),
            'student.role.revoke' => $this->op('POST', '/api/escolar/student-roles/{id}/revoke'),
            'teacher.role.create' => $this->op('POST', '/api/escolar/teacher-roles'),
            'teacher.role.update' => $this->op('PUT', '/api/escolar/teacher-roles/{id}'),
            'teacher.role.revoke' => $this->op('POST', '/api/escolar/teacher-roles/{id}/revoke'),
            'attendance.create' => $this->op('POST', '/api/escolar/attendance'),
            'attendance.update' => $this->op('PUT', '/api/escolar/attendance/{id}'),
            'grade.item.list' => $this->op('GET', '/api/escolar/grade-items'),
            'grade.item.create' => $this->op('POST', '/api/escolar/grade-items'),
            'grade.item.publish' => $this->op('POST', '/api/escolar/grade-items/{id}/publish'),
            'grade.create' => $this->op('POST', '/api/escolar/grades'),
            'grade.update' => $this->op('PUT', '/api/escolar/grades/{id}'),
            'report.card.view' => $this->op('GET', '/api/escolar/report-cards/{student_id}'),
            'time.slot.list' => $this->op('GET', '/api/escolar/time-slots'),
            'time.slot.create' => $this->op('POST', '/api/escolar/time-slots'),
            'timetable.class.view' => $this->op('GET', '/api/escolar/timetables/class/{class_id}'),
            'timetable.teacher.view' => $this->op('GET', '/api/escolar/timetables/teacher/{teacher_id}'),
            'timetable.create' => $this->op('POST', '/api/escolar/timetables'),
            'timetable.update' => $this->op('PUT', '/api/escolar/timetables/{id}'),
            'timetable.delete' => $this->op('DELETE', '/api/escolar/timetables/{id}'),
            'calendar.event.type.list' => $this->op('GET', '/api/escolar/calendar-event-types'),
            'calendar.event.type.create' => $this->op('POST', '/api/escolar/calendar-event-types'),
            'calendar.event.list' => $this->op('GET', '/api/escolar/calendar-events'),
            'calendar.event.view' => $this->op('GET', '/api/escolar/calendar-events/{id}'),
            'calendar.event.create' => $this->op('POST', '/api/escolar/calendar-events'),
            'calendar.event.update' => $this->op('PUT', '/api/escolar/calendar-events/{id}'),
            'calendar.event.delete' => $this->op('DELETE', '/api/escolar/calendar-events/{id}'),
            'incident.type.list' => $this->op('GET', '/api/escolar/incident-types'),
            'incident.type.create' => $this->op('POST', '/api/escolar/incident-types'),
            'incident.list' => $this->op('GET', '/api/escolar/incidents'),
            'incident.view' => $this->op('GET', '/api/escolar/incidents/{id}'),
            'incident.create' => $this->op('POST', '/api/escolar/incidents'),
            'incident.update' => $this->op('PUT', '/api/escolar/incidents/{id}'),
            'sanction.create' => $this->op('POST', '/api/escolar/sanctions'),
            'merit.create' => $this->op('POST', '/api/escolar/merits'),
            'fee.plan.create' => $this->op('POST', '/api/escolar/fee-plans'),
            'fee.plan.generate' => $this->op('POST', '/api/escolar/fee-plans/{id}/generate'),
            'student.invoice.view' => $this->op('GET', '/api/escolar/student-invoices/{id}'),
            'student.invoice.create' => $this->op('POST', '/api/escolar/student-invoices'),
            'student.invoice.emit' => $this->op('POST', '/api/escolar/student-invoices/{id}/emit'),
            'student.invoice.discount' => $this->op('POST', '/api/escolar/student-invoices/{id}/discount'),
            'payment.create' => $this->op('POST', '/api/escolar/payments'),
            'payment.view' => $this->op('GET', '/api/escolar/payments/{id}'),
            'payment.receipt' => $this->op('GET', '/api/escolar/payments/{id}/receipt'),
            'book.create' => $this->op('POST', '/api/escolar/library/books'),
            'loan.create' => $this->op('POST', '/api/escolar/library/loans'),
            'loan.return' => $this->op('POST', '/api/escolar/library/loans/{id}/return'),
            'message.create' => $this->op('POST', '/api/escolar/messages'),
            'message.publish' => $this->op('POST', '/api/escolar/messages/{id}/publish'),
        ];
    }

    private function op(string $method, string $path): array
    {
        return ['method' => $method, 'path' => $path];
    }

    public function getFinancialConfig(): array
    {
        $resp = $this->gateway->request('GET', '/api/escolar/config/financial');
        if ($resp->status === 404) {
            return [];
        }
        if ($resp->status >= 400) {
            throw new \E258Tech\Model\Exception\OperationException('Erro ao obter configuracao financeira.');
        }
        return (array) ($resp->body ?? []);
    }

    public function saveFinancialConfig(array $payload): array
    {
        $resp = $this->gateway->request('POST', '/api/escolar/config/financial', $payload);
        if ($resp->status >= 400) {
            throw new \E258Tech\Model\Exception\OperationException('Erro ao guardar configuracao financeira.');
        }
        return ['ok' => true];
    }
}
