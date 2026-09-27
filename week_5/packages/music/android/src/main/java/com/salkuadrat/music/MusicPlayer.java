package com.salkuadrat.music;

import android.app.Activity;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.os.PowerManager;
import android.net.Uri;


import java.io.IOException;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.MethodChannel;

public class MusicPlayer implements MediaPlayer.OnPreparedListener,
    MediaPlayer.OnCompletionListener {

    private final MediaPlayer player = new MediaPlayer();

    private Timer timer;
    private TimerTask task;
    private boolean closed = false;

    private final Activity context;
    private final MethodChannel channel;
    private final Runnable onPositionUpdated;

    MusicPlayer(MethodChannel channel, Activity context, Runnable onPositionUpdated) {
        this.channel = channel;
        this.context = context;
        this.onPositionUpdated = onPositionUpdated;

        AudioAttributes audioAttributes = new AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .build();
        player.setAudioAttributes(audioAttributes);

        // Make sure the media player will acquire a wake-lock while playing.
        // If we don't do that, the CPU might go to sleep while the
        // song is playing, causing playback to stop.
        player.setWakeMode(context, PowerManager.PARTIAL_WAKE_LOCK);
        player.reset();

        // we want the media player to notify us when it's ready preparing,
        // and when it's done playing
        //player.setOnInfoListener(this);
        player.setOnPreparedListener(this);
        player.setOnCompletionListener(this);
        player.setOnErrorListener((mp, what, extra) -> {
            channel.invokeMethod("onError", "Playback failed: " + what);
            return true;
        });
        //player.setOnBufferingUpdateListener(this);
    }

    public void play(String url) {
        //Log.v("MusicPlayer", "play " + url);
        player.reset();
        channel.invokeMethod("onLoading", true);
        channel.invokeMethod("onPosition", 0);

        //Log.v("MusicPlayer", "url " + url);
        //Log.v("MusicPlayer", "Proxy Url " + proxyUrl);

        try {
            player.setDataSource(context, Uri.parse(url));
            player.prepareAsync();
            startTask();
        } catch (IOException | IllegalArgumentException e) {
            channel.invokeMethod("onError", e.getMessage());
        }
    }

    private void startTask() {
        if (task != null) {
            task.cancel();
        }

        if (timer != null) {
            timer.cancel();
        }

        timer = new Timer();
        task = new TimerTask() {
            @Override
            public void run() {
                context.runOnUiThread(() -> {
                    if (!closed && player.isPlaying()) {
                        onPosition();
                        onPositionUpdated.run();
                    }
                });
            }
        };

        timer.schedule(task, 0, 1000);
    }

    public int getCurrentPosition() {
        return player.getCurrentPosition();
    }

    public boolean isPlaying() {
        return !closed && player.isPlaying();
    }

    public int getDuration() {
        return player.getDuration();
    }

    private void onPosition() {
        channel.invokeMethod("onPosition", player.getCurrentPosition());
    }

    public void pause() {
        if (player.isPlaying()) {
            if (task != null) {
                task.cancel();
            }

            if (timer != null) {
                timer.cancel();
            }

            player.pause();
            channel.invokeMethod("onPaused", null);
        }
    }

    public void resume() {
        if (!player.isPlaying()) {
            startTask();
            player.start();
            channel.invokeMethod("onPlaying", null);
        }
    }

    public void stop() {
        if (task != null) {
            task.cancel();
        }

        if (timer != null) {
            timer.cancel();
        }

        player.reset();
        channel.invokeMethod("onStopped", null);
    }

    public void seek(int position) {
        if (task != null) {
            task.cancel();
        }

        if (timer != null) {
            timer.cancel();
        }

        player.seekTo(position);
        startTask();
    }

    public void playPrevious() {
        channel.invokeMethod("onPlayPrevious", null);
    }

    public void playNext() {
        channel.invokeMethod("onPlayNext", null);
    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        // The media player is done preparing.
        // That means we can start playing if we have audio focus.
        player.start();

        // call flutter channel to update duration & playing status
        channel.invokeMethod("onDuration", player.getDuration());
        channel.invokeMethod("onPlaying", null);
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        if (task != null) {
            task.cancel();
        }

        if (timer != null) {
            timer.cancel();
        }

        player.seekTo(0);
        channel.invokeMethod("onCompleted", null);
        onPosition();
        onPositionUpdated.run();
    }

    public void close() {
        if (closed) return;
        closed = true;
        if (task != null) {
            task.cancel();
        }

        if (timer != null) {
            timer.cancel();
            timer.purge();
        }

        player.reset();
        player.release();
    }
}
