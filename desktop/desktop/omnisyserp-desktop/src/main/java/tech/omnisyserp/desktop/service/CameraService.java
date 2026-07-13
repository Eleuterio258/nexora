package tech.omnisyserp.desktop.service;

import lombok.extern.slf4j.Slf4j;
import org.opencv.core.*;
import org.opencv.imgproc.Imgproc;
import org.opencv.objdetect.CascadeClassifier;
import org.opencv.videoio.VideoCapture;
import org.springframework.stereotype.Service;

import jakarta.annotation.PreDestroy;
import java.awt.image.BufferedImage;
import java.awt.image.DataBufferByte;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
public class CameraService {

    private VideoCapture capture;
    private CascadeClassifier faceDetector;
    private boolean opencvDisponivel = false;
    private boolean cameraAberta = false;
    private Path cascadeTempFile;

    public CameraService() {
        inicializarOpenCV();
    }

    private void inicializarOpenCV() {
        try {
            nu.pattern.OpenCV.loadLocally();
            inicializarCascade();
            opencvDisponivel = true;
            log.info("OpenCV inicializado com sucesso.");
        } catch (Throwable e) {
            log.warn("OpenCV nao disponivel: {}. Funcionalidades de camera desactivadas.", e.getMessage());
        }
    }

    private void inicializarCascade() {
        try {
            InputStream is = getClass().getResourceAsStream("/haarcascade_frontalface_default.xml");
            if (is != null) {
                cascadeTempFile = Files.createTempFile("haarcascade", ".xml");
                Files.copy(is, cascadeTempFile, StandardCopyOption.REPLACE_EXISTING);
                faceDetector = new CascadeClassifier(cascadeTempFile.toString());
                if (!faceDetector.empty()) {
                    log.info("Classificador de faces carregado.");
                } else {
                    log.warn("Ficheiro cascade carregado mas vazio.");
                    faceDetector = null;
                }
                is.close();
            } else {
                log.warn("haarcascade_frontalface_default.xml nao encontrado nos recursos.");
            }
        } catch (IOException e) {
            log.warn("Erro ao carregar cascade: {}", e.getMessage());
        }
    }

    public boolean isOpencvDisponivel() {
        return opencvDisponivel;
    }

    public boolean abrirCamera(int index) {
        if (!opencvDisponivel) return false;
        if (cameraAberta) fecharCamera();

        capture = new VideoCapture(index);
        cameraAberta = capture.isOpened();
        if (cameraAberta) {
            capture.set(3, 640); // largura
            capture.set(4, 480); // altura
            log.info("Camera {} aberta.", index);
        } else {
            log.warn("Nao foi possivel abrir a camera {}.", index);
        }
        return cameraAberta;
    }

    public boolean isCameraAberta() {
        return cameraAberta && capture != null && capture.isOpened();
    }

    public void fecharCamera() {
        if (capture != null && capture.isOpened()) {
            capture.release();
            log.info("Camera fechada.");
        }
        cameraAberta = false;
    }

    /**
     * Captura um frame da camera e retorna como BufferedImage.
     * Desenha rectangulos de deteccao de faces se disponivel.
     */
    public FrameResult capturarFrame() {
        if (!isCameraAberta()) return null;

        Mat frame = new Mat();
        if (!capture.read(frame) || frame.empty()) return null;

        List<Rect> faces = detectarFaces(frame);

        // Codificar JPEG: crop do rosto com padding para o backend dlib/HOG
        // O backend exige que o rosto ocupe >= 15% da area da imagem.
        // Enviar o frame completo (640x480) com rosto de 60x60 daria ~1% — dlib falha.
        byte[] jpegBytes = null;
        if (!faces.isEmpty()) {
            Rect r = faces.get(0);
            int pad = Math.max(40, (int)(r.width * 0.55));
            int cx = r.x + r.width / 2;
            int cy = r.y + r.height / 2;
            int half = Math.max(r.width, r.height) / 2 + pad;
            int x0 = Math.max(0, cx - half);
            int y0 = Math.max(0, cy - half);
            int x1 = Math.min(frame.cols(), cx + half);
            int y1 = Math.min(frame.rows(), cy + half);
            Mat crop = frame.submat(new Rect(x0, y0, x1 - x0, y1 - y0));
            MatOfByte mob = new MatOfByte();
            MatOfInt params = new MatOfInt(
                    org.opencv.imgcodecs.Imgcodecs.IMWRITE_JPEG_QUALITY, 92);
            org.opencv.imgcodecs.Imgcodecs.imencode(".jpg", crop, mob, params);
            jpegBytes = mob.toArray();
            mob.release();
        }

        // Desenhar rectangulos para display
        for (Rect r : faces) {
            Imgproc.rectangle(frame,
                    new Point(r.x, r.y),
                    new Point(r.x + r.width, r.y + r.height),
                    new Scalar(0, 255, 0), 2);
        }

        java.awt.Rectangle primeirRosto = null;
        if (!faces.isEmpty()) {
            Rect r = faces.get(0);
            primeirRosto = new java.awt.Rectangle(r.x, r.y, r.width, r.height);
        }

        BufferedImage imagem = matParaBufferedImage(frame);
        int larguraFrame = frame.cols();
        frame.release();

        return new FrameResult(imagem, faces.size(), primeirRosto, larguraFrame, jpegBytes);
    }

    /**
     * Captura um frame puro (sem anotacoes) como bytes JPEG.
     * Valida que existe pelo menos um rosto detectado antes de retornar.
     * Retorna null se a camera nao estiver aberta, o frame estiver vazio
     * ou nenhum rosto for detectado.
     */
    public byte[] capturarFrameBytes() {
        if (!isCameraAberta()) return null;

        Mat frame = new Mat();
        if (!capture.read(frame) || frame.empty()) return null;

        List<Rect> faces = detectarFaces(frame);
        if (faces.isEmpty()) {
            frame.release();
            log.debug("Captura rejeitada: nenhum rosto detectado no frame.");
            return null;
        }

        MatOfByte mob = new MatOfByte();
        org.opencv.imgcodecs.Imgcodecs.imencode(".jpg", frame, mob);
        byte[] bytes = mob.toArray();
        frame.release();
        mob.release();
        return bytes;
    }

    private List<Rect> detectarFaces(Mat frame) {
        if (faceDetector == null || faceDetector.empty()) return new ArrayList<>();

        Mat cinzento = new Mat();
        Imgproc.cvtColor(frame, cinzento, Imgproc.COLOR_BGR2GRAY);
        Imgproc.equalizeHist(cinzento, cinzento);

        MatOfRect faces = new MatOfRect();
        faceDetector.detectMultiScale(cinzento, faces, 1.1, 3,
                0, new Size(60, 60), new Size());

        cinzento.release();
        List<Rect> lista = new ArrayList<>(faces.toList());
        faces.release();
        return lista;
    }

    private BufferedImage matParaBufferedImage(Mat mat) {
        Mat bgr = new Mat();
        Imgproc.cvtColor(mat, bgr, Imgproc.COLOR_BGR2RGB);

        int tipo = BufferedImage.TYPE_3BYTE_BGR;
        BufferedImage img = new BufferedImage(bgr.cols(), bgr.rows(), tipo);
        byte[] data = ((DataBufferByte) img.getRaster().getDataBuffer()).getData();
        bgr.get(0, 0, data);
        bgr.release();
        return img;
    }

    @PreDestroy
    public void destruir() {
        fecharCamera();
        if (cascadeTempFile != null) {
            try { Files.deleteIfExists(cascadeTempFile); } catch (IOException ignored) {}
        }
    }

    public record FrameResult(BufferedImage imagem, int facesDetectadas, java.awt.Rectangle primeirRosto, int larguraFrame, byte[] jpegBytes) {}
}
