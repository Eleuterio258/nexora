package adapters

import "sync"

// Registry mantém os adapters registados no sistema.
type Registry struct {
	mu      sync.RWMutex
	adapters map[string]Adapter
}

// NewRegistry cria um registo vazio.
func NewRegistry() *Registry {
	return &Registry{
		adapters: make(map[string]Adapter),
	}
}

// Register adiciona um adapter ao registo.
func (r *Registry) Register(a Adapter) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.adapters[a.Name()] = a
}

// Get obtém um adapter pelo nome.
func (r *Registry) Get(name string) (Adapter, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	a, ok := r.adapters[name]
	return a, ok
}

// List devolve a lista de nomes dos drivers registados.
func (r *Registry) List() []string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	names := make([]string, 0, len(r.adapters))
	for name := range r.adapters {
		names = append(names, name)
	}
	return names
}

// DefaultRegistry contém os drivers padrão do Nexora ERP.
var DefaultRegistry = NewRegistry()

func init() {
	DefaultRegistry.Register(&HikvisionAdapter{})
	DefaultRegistry.Register(&GenericRESTAdapter{})
	DefaultRegistry.Register(&ZKTecoAdapter{})
}
