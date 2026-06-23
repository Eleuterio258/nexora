<?php
declare(strict_types=1);

namespace E258Tech\Model\Exception;

use RuntimeException;

class OperationException extends RuntimeException
{
    public function __construct(string $message, public readonly int $status = 422)
    {
        parent::__construct($message);
    }
}
