package com.pacificmetrics.orca.tts;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.SequenceInputStream;
import java.util.Vector;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.sound.sampled.AudioFileFormat;
import javax.sound.sampled.AudioFileFormat.Type;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;

import com.sun.speech.freetts.audio.AudioPlayer;

public class StreamAudioPlayer implements AudioPlayer {

	private static final Logger LOGGER = Logger
            .getLogger(StreamAudioPlayer.class.getName());
    private AudioFormat currentFormat = null;
    private String baseName;
    private byte[] outputData;
    private int curIndex = 0;
    private int totBytes = 0;
    private final AudioFileFormat.Type outputType;
    private final Vector outputList;

    public StreamAudioPlayer() {
        this(Type.WAVE);
    }

    public StreamAudioPlayer(AudioFileFormat.Type type) {
        outputType = type;

        outputList = new Vector();
    }

    /**
     * Sets the audio format for this player
     * 
     * @param format
     *            the audio format
     * 
     * @throws UnsupportedOperationException
     *             if the line cannot be opened with the given format
     */
    @Override
    public synchronized void setAudioFormat(AudioFormat format) {
        currentFormat = format;
    }

    /**
     * Gets the audio format for this player
     * 
     * @return format the audio format
     */
    @Override
    public AudioFormat getAudioFormat() {
        return currentFormat;
    }

    /**
     * Pauses audio output
     */
    @Override
    public void pause() {
    	// Do nothing
    }

    /**
     * Resumes audio output
     */
    @Override
    public synchronized void resume() {
    	// Do nothing
    }

    /**
     * Cancels currently playing audio
     */
    @Override
    public synchronized void cancel() {
    	// Do nothing
    }

    /**
     * Prepares for another batch of output. Larger groups of output (such as
     * all output associated with a single FreeTTSSpeakable) should be grouped
     * between a reset/drain pair.
     */
    @Override
    public synchronized void reset() {
    	// Do nothing
    }

    /**
     * Starts the first sample timer
     */
    @Override
    public void startFirstSampleTimer() {
    	// Do nothing
    }

    /**
     * Closes this audio player
     */
    @Override
    public synchronized void close() {
        try {
            InputStream is = new SequenceInputStream(outputList.elements());
            is.close();
        } catch (IOException ioe) {            
            LOGGER.log(Level.SEVERE,
                    "Can't write audio to : " + baseName + ":" + ioe.getMessage(), ioe);
        } catch (IllegalArgumentException iae) {            
            LOGGER.log(Level.SEVERE,
                    "Can't write audio type : " + outputType + ":" + iae.getMessage(), iae);
        }
    }

    public byte[] getBytes() {
        try {
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            InputStream is = new SequenceInputStream(outputList.elements());
            AudioInputStream ais = new AudioInputStream(is, currentFormat,
                    totBytes / currentFormat.getFrameSize());
            AudioSystem.write(ais, outputType, outputStream);

            return outputStream.toByteArray();
        } catch (IllegalArgumentException iae) {           
            LOGGER.log(Level.SEVERE,
                    "Can't write audio type : " + outputType + ":" + iae.getMessage(), iae);            
        } catch (IOException e) {
        	LOGGER.log(Level.SEVERE,
                    "Can't write audio type : " + outputType + ":" + e.getMessage(), e);
        }
        return null;
    }

    /**
     * Returns the current volume.
     * 
     * @return the current volume (between 0 and 1)
     */
    @Override
    public float getVolume() {
        return 1.0f;
    }

    /**
     * Sets the current volume.
     * 
     * @param volume
     *            the current volume (between 0 and 1)
     */
    @Override
    public void setVolume(float volume) {
    	// Do nothing
    }

    /**
     * Starts the output of a set of data. Audio data for a single utterance
     * should be grouped between begin/end pairs.
     * 
     * @param size
     *            the size of data between now and the end
     */
    @Override
    public void begin(int size) {
        outputData = new byte[size];
        curIndex = 0;
    }

    /**
     * Marks the end of a set of data. Audio data for a single utterance should
     * be groupd between begin/end pairs.
     * 
     * @return true if the audio was output properly, false if the output was
     *         cancelled or interrupted.
     * 
     */
    @Override
    public boolean end() {
        outputList.add(new ByteArrayInputStream(outputData));
        totBytes += outputData.length;
        return true;
    }

    /**
     * Waits for all queued audio to be played
     * 
     * @return true if the audio played to completion, false if the audio was
     *         stopped
     */
    @Override
    public boolean drain() {
        return true;
    }

    /**
     * Gets the amount of played since the last mark
     * 
     * @return the amount of audio in milliseconds
     */
    @Override
    public synchronized long getTime() {
        return -1L;
    }

    /**
     * Resets the audio clock
     */
    @Override
    public synchronized void resetTime() {
    	// Do nothing
    }

    /**
     * Writes the given bytes to the audio stream
     * 
     * @param audioData
     *            audio data to write to the device
     * 
     * @return <code>true</code> of the write completed successfully,
     *         <code> false </code>if the write was cancelled.
     */
    @Override
    public boolean write(byte[] audioData) {
        return write(audioData, 0, audioData.length);
    }

    /**
     * Writes the given bytes to the audio stream
     * 
     * @param bytes
     *            audio data to write to the device
     * @param offset
     *            the offset into the buffer
     * @param size
     *            the size into the buffer
     * 
     * @return <code>true</code> of the write completed successfully,
     *         <code> false </code>if the write was cancelled.
     */
    @Override
    public boolean write(byte[] bytes, int offset, int size) {
        System.arraycopy(bytes, offset, outputData, curIndex, size);
        curIndex += size;
        return true;
    }

    /**
     * Returns the name of this audioplayer
     * 
     * @return the name of the audio player
     */
    @Override
    public String toString() {
        return "FileAudioPlayer";
    }

    /**
     * Shows metrics for this audio player
     */
    @Override
    public void showMetrics() {
    	// Do nothing
    }

}
