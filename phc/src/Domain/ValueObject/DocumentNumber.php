<?php

declare(strict_types=1);

namespace PHC\Domain\ValueObject;

final readonly class DocumentNumber
{
    public function __construct(
        private DocumentType $type,
        private string $seriesCode,
        private int $year,
        private int $sequential,
        private ?string $raw = null
    ) {
        if ($this->sequential < 1) {
            throw new \InvalidArgumentException('Sequencial deve ser maior ou igual a 1.');
        }
    }

    /**
     * Documentos vindos da API do backend já trazem o número final formatado
     * pelo servidor (ex.: "FT0001", "PRO-42") em vez de tipo/série/ano/
     * sequencial separados — não há como decompor isso com segurança, por
     * isso guarda-se tal como veio e devolve-se verbatim em __toString().
     */
    public static function fromRaw(DocumentType $type, string $raw): self
    {
        return new self($type, $raw, (int) date('Y'), 1, $raw);
    }

    public function type(): DocumentType
    {
        return $this->type;
    }

    public function seriesCode(): string
    {
        return $this->seriesCode;
    }

    public function year(): int
    {
        return $this->year;
    }

    public function sequential(): int
    {
        return $this->sequential;
    }

    public function __toString(): string
    {
        if ($this->raw !== null) {
            return $this->raw;
        }

        return sprintf(
            '%s %s/%d-%06d',
            $this->type->value(),
            $this->seriesCode,
            $this->year,
            $this->sequential
        );
    }
}
