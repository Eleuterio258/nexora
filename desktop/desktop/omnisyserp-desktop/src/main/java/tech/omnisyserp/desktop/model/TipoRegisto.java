package tech.omnisyserp.desktop.model;

public enum TipoRegisto {
    PRESENCIAL("Presencial"),
    REMOTO("Remoto"),
    FERIAS("Ferias"),
    BAIXA("Baixa Medica"),
    FORMACAO("Formacao");

    private final String label;

    TipoRegisto(String label) {
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    @Override
    public String toString() {
        return label;
    }
}
