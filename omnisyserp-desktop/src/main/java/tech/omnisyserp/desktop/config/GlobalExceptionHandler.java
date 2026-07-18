package tech.omnisyserp.desktop.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.swing.*;

/**
 * Handler global de exceções não apanhadas em threads Swing.
 * Previne crashes silenciosas e mostra erros ao utilizador.
 */
@Component
@Slf4j
public class GlobalExceptionHandler implements Thread.UncaughtExceptionHandler {

    @Override
    public void uncaughtException(Thread t, Throwable e) {
        log.error("Exceção nao apanhada na thread: {}", t.getName(), e);
        
        // Se for EDT (Event Dispatch Thread), mostrar dialog ao utilizador
        if (SwingUtilities.isEventDispatchThread() || t.getName().contains("AWT")) {
            SwingUtilities.invokeLater(() -> showErrorMessage(e));
        }
    }

    private void showErrorMessage(Throwable e) {
        String mensagem = "Ocorreu um erro inesperado:\n\n" +
                e.getMessage() +
                "\n\nPor favor contacte o suporte tecnico.";
        
        JOptionPane.showMessageDialog(
                null,
                mensagem,
                "Erro Inesperado",
                JOptionPane.ERROR_MESSAGE
        );
    }

    /**
     * Registra o handler global.
     * Deve ser chamado no inicio da aplicacao.
     */
    public static void register() {
        GlobalExceptionHandler handler = new GlobalExceptionHandler();
        Thread.setDefaultUncaughtExceptionHandler(handler);
        
        // Tambem registrar para threads do SwingWorker
        UIManager.put("ClassLoader", GlobalExceptionHandler.class.getClassLoader());
    }
}
