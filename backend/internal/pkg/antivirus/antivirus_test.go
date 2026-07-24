package antivirus

import (
	"testing"
)

func TestNoop_AlwaysClean(t *testing.T) {
	n := &noop{}
	res, err := n.Verificar("test.pdf", []byte("%PDF-1.4 fake"))
	if err != nil {
		t.Fatalf("erro inesperado: %v", err)
	}
	if !res.Limpo || res.Infectado {
		t.Errorf("noop deve sempre devolver limpo, got %+v", res)
	}
}

func TestNew_DefaultIsNoop(t *testing.T) {
	v := New(Config{Provider: ""})
	_, ok := v.(*noop)
	if !ok {
		t.Errorf("provider vazio deve devolver noop, got %T", v)
	}
}

func TestNew_UnknownProviderIsNoop(t *testing.T) {
	v := New(Config{Provider: "desconhecido"})
	_, ok := v.(*noop)
	if !ok {
		t.Errorf("provider desconhecido deve devolver noop, got %T", v)
	}
}

func TestNew_Clamav(t *testing.T) {
	v := New(Config{Provider: "clamav", ClamAVNetwork: "tcp", ClamAVAddress: "localhost:3310"})
	_, ok := v.(*clamav)
	if !ok {
		t.Errorf("provider clamav deve devolver *clamav, got %T", v)
	}
}
