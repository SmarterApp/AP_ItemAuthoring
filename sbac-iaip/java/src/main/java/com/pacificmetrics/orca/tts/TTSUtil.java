package com.pacificmetrics.orca.tts;

import java.beans.PropertyVetoException;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.Locale;

import javax.sound.sampled.AudioFileFormat.Type;
import javax.speech.AudioException;
import javax.speech.Central;
import javax.speech.EngineException;
import javax.speech.EngineStateError;
import javax.speech.synthesis.Synthesizer;
import javax.speech.synthesis.SynthesizerModeDesc;
import javax.speech.synthesis.Voice;

public class TTSUtil {

    SynthesizerModeDesc desc;
    Synthesizer synthesizer;
    Voice voice;
    StreamAudioPlayer audioPlayer = null;

    public void init() throws EngineException, AudioException,
            EngineStateError, PropertyVetoException {
        if (desc == null) {
            String voiceName = "kevin16";
            audioPlayer = new StreamAudioPlayer(Type.WAVE);

            System.setProperty("freetts.voices",
                    "com.sun.speech.freetts.en.us.cmu_us_kal.KevinVoiceDirectory");

            desc = new SynthesizerModeDesc(Locale.US);
            Central.registerEngineCentral("com.sun.speech.freetts.jsapi.FreeTTSEngineCentral");
            synthesizer = Central.createSynthesizer(desc);
            synthesizer.allocate();
            synthesizer.resume();
            SynthesizerModeDesc smd = (SynthesizerModeDesc) synthesizer
                    .getEngineModeDesc();
            Voice[] voices = smd.getVoices();
            Voice voice = null;
            for (int i = 0; i < voices.length; i++) {
                if (voices[i].getName().equals(voiceName)) {
                    voice = voices[i];
                    break;
                }
            }
            /*
             * Non-JSAPI modification of voice audio player
             */
            if (voice instanceof com.sun.speech.freetts.jsapi.FreeTTSVoice) {
                com.sun.speech.freetts.Voice freettsVoice = ((com.sun.speech.freetts.jsapi.FreeTTSVoice) voice)
                        .getVoice();
                freettsVoice.setAudioPlayer(audioPlayer);
                freettsVoice.setRate(125.0f);
                freettsVoice.setPitchRange(12.5f);
                freettsVoice.setPitch(80.0f);
            }
            synthesizer.getSynthesizerProperties().setVoice(voice);
        }
    }

    public byte[] getAudioBytes() throws Exception {
        return convertToMp3Data(audioPlayer.getBytes());
    }

    private byte[] convertToMp3Data(byte[] wavAudioData) throws Exception {
        String tempDir = "/tmp";
        String fileName = String.valueOf(System.currentTimeMillis());
        String wavFilePath = tempDir + File.separator + fileName + ".wav";
        String mp3FilePath = tempDir + File.separator + fileName + ".mp3";

        File wavFile = new File(wavFilePath);
        FileOutputStream fos = new FileOutputStream(wavFile);
        fos.write(wavAudioData);
        fos.close();

        SoundUtil.wavToMP3(wavFilePath, mp3FilePath);
        wavFile.delete();

        File mp3File = new File(mp3FilePath);
        FileInputStream fis = new FileInputStream(mp3FilePath);
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();

        int nRead;
        byte[] data = new byte[16384];

        while ((nRead = fis.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, nRead);
        }

        buffer.flush();
        fis.close();
        mp3File.delete();
        return buffer.toByteArray();
    }

    public void terminate() throws EngineException, EngineStateError {
        synthesizer.deallocate();
    }

    public void doSpeak(String speakText) throws EngineException,
            AudioException, IllegalArgumentException, InterruptedException {
        synthesizer.speakPlainText(speakText, null);
        synthesizer.waitEngineState(Synthesizer.QUEUE_EMPTY);
    }

}
