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
            'class.view' => $this->op('GET', '/api/escolar/classes/{id}'),
            'class.create' => $this->op('POST', '/api/escolar/classes'),
            'class.update' => $this->op('PUT', '/api/escolar/classes/{id}'),
            'class.teacher' => $this->op('POST', '/api/escolar/classes/{id}/assign-teacher'),
            'subject.create' => $this->op('POST', '/api/escolar/subjects'),
            'teacher.assignment.create' => $this->op('POST', '/api/escolar/teacher-assignments'),
            'student.view' => $this->op('GET', '/api/escolar/students/{id}'),
            'student.create' => $this->op('POST', '/api/escolar/students'),
            'student.update' => $this->op('PUT', '/api/escolar/students/{id}'),
            'guardian.create' => $this->op('POST', '/api/escolar/students/{id}/guardians'),
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
            'grade.item.create' => $this->op('POST', '/api/escolar/grade-items'),
            'grade.create' => $this->op('POST', '/api/escolar/grades'),
            'grade.update' => $this->op('PUT', '/api/escolar/grades/{id}'),
            'report.card.view' => $this->op('GET', '/api/escolar/report-cards/{student_id}'),
            'fee.plan.create' => $this->op('POST', '/api/escolar/fee-plans'),
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
}
