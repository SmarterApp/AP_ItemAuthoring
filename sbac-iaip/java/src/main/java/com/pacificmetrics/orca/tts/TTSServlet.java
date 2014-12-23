package com.pacificmetrics.orca.tts;

import java.beans.PropertyVetoException;
import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.speech.AudioException;
import javax.speech.EngineException;
import javax.speech.EngineStateError;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * Servlet implementation class TTSServlet
 */
@WebServlet("/TTSServlet")
public class TTSServlet extends HttpServlet {

    private static final Log LOGGER = LogFactory.getLog(TTSServlet.class);

    private static final long serialVersionUID = 1L;

    private TTSUtil ttsUtil = new TTSUtil();

    /**
     * @see HttpServlet#HttpServlet()
     */
    public TTSServlet() {
        super();
    }

    @Override
    public void destroy() {
        try {
            ttsUtil.terminate();
        } catch (EngineException e) {
            LOGGER.error("Error destroying TTS engine " + e.getMessage(), e);
        } catch (EngineStateError e) {
            LOGGER.error(
                    "Error destroying TTS engine with invalid state "
                            + e.getMessage(), e);
        }
        super.destroy();
    }

    @Override
    public void init() throws ServletException {
        super.init();
        try {
            ttsUtil.init();
        } catch (EngineException e) {
            LOGGER.error("Error initializing TTS engine " + e.getMessage(), e);
        } catch (AudioException e) {
            LOGGER.error(
                    "Error initializing TTS engine with audio "
                            + e.getMessage(), e);
        } catch (EngineStateError e) {
            LOGGER.error("Error initializing TTS engine with invlaid state "
                    + e.getMessage(), e);
        } catch (PropertyVetoException e) {
            LOGGER.error(
                    "Error initializing TTS engine with property "
                            + e.getMessage(), e);
        } catch (IllegalArgumentException e) {
            LOGGER.error("Error initializing TTS engine with invalid argument "
                    + e.getMessage(), e);
        }
    }

    /**
     * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse
     *      response)
     */
    @Override
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        doProcess(request, response);
    }

    /**
     * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse
     *      response)
     */
    @Override
    protected void doPost(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        doProcess(request, response);
    }

    public void doProcess(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        try {
            String text = request.getParameter("text");
            if (StringUtils.isBlank(text)) {
                text = "";
            }
            String result = java.net.URLDecoder.decode(text, "UTF-8");
            LOGGER.info("TTS text : " + result);
            OutputStream outputStream = response.getOutputStream();
            ttsUtil.doSpeak(result);
            byte[] mp3AudioData = ttsUtil.getAudioBytes();
            response.setContentType("audio/mp3");
            outputStream.write(mp3AudioData);
        } catch (EngineException e) {
            LOGGER.error(
                    "Error TTS engine converting text to speech "
                            + e.getMessage(), e);
        } catch (AudioException e) {
            LOGGER.error(
                    "Error TTS engine converting text to audio "
                            + e.getMessage(), e);
        } catch (EngineStateError e) {
            LOGGER.error("Error TTS engine converting text with invalid state "
                    + e.getMessage(), e);
        } catch (IllegalArgumentException e) {
            LOGGER.error(
                    "Error TTS engine converting text with invlaid argument "
                            + e.getMessage(), e);
        } catch (InterruptedException e) {
            LOGGER.error(
                    "Error TTS engine converting text with thread interruption "
                            + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.error(
                    "Error TTS engine converting text to speech "
                            + e.getMessage(), e);
        }
    }

}
