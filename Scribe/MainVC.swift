//
//  ViewController.swift
//  Scribe
//
//  Created by AADITYA NARVEKAR on 7/14/17.
//  Copyright © 2017 Aaditya Narvekar. All rights reserved.
//

import UIKit
import Speech
import AVFoundation
import Toaster

class MainVC: UIViewController, SFSpeechRecognizerDelegate {
    
    
    @IBOutlet weak var playAndTranscribeBtn: UIButton!
    @IBOutlet weak var transcribedText: UITextView!
    @IBOutlet weak var instructionLbl: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var clearBtn: UIButton!
    
    
    private var _isListening: Bool! = false
    private var _hasTranscribedText: Bool! = false
    private var _authorized: Bool! = false
    
    var toast:Toast?
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let sfSpeechRecognizer = SFSpeechRecognizer(locale: .current)
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        playAndTranscribeBtn.makeSquareViewCircular()
        setUpInitialState()
        sfSpeechRecognizer?.delegate = self
    }
    
    @IBAction func transcribeAndPlayBtnTapped(_ sender: Any) {
        if SFSpeechRecognizer.authorizationStatus() == SFSpeechRecognizerAuthorizationStatus.authorized {
            prepareForListeningAndTranscribing()
        } else if SFSpeechRecognizer.authorizationStatus() == SFSpeechRecognizerAuthorizationStatus.denied {
            print("Access denied")
            let alert = UIAlertController(title: "Access denied", message: "Please provide access via Settings", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let settingsAction = UIAlertAction(title: "Go to Settings", style: .default, handler: { (action) in
                let settingsUrl = URL(string: UIApplicationOpenSettingsURLString)
                UIApplication.shared.open(settingsUrl!, options: [:], completionHandler: nil)
            })
            alert.addAction(cancelAction)
            alert.addAction(settingsAction)
            present(alert, animated: true, completion: nil)
        } else if SFSpeechRecognizer.authorizationStatus() == SFSpeechRecognizerAuthorizationStatus.notDetermined {
            requestSpeechAuthorization()
        } else {
            print("Resrticted Access. Not sure how to handle")
        }
        
    }
    
    private func prepareForListeningAndTranscribing() {
        toast?.cancel()
        copyBtn.isEnabled = transcribedText.text.characters.count > 0
        clearBtn.isEnabled = _hasTranscribedText
        if !_isListening {
            instructionLbl.text = "Listening & transcribing..."
            transcribedText.text = ""
            startRecordingAndTranscribing()
        } else {
            instructionLbl.text = "Tap to transcribe"
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode?.removeTap(onBus: 0)
                recognitionRequest?.endAudio()
            }
        }
        _isListening = !_isListening
    }
    
    private func startRecordingAndTranscribing() {
        if let _ = recognitionTask {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch let err as NSError {
            print("Error setting up audio session: \(err.debugDescription)")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Unable to set up input node")
        }
        guard let _ = recognitionRequest else {
            fatalError("Unable to configure recognition request")
        }
        
        recognitionTask = sfSpeechRecognizer?.recognitionTask(with: recognitionRequest!, resultHandler: { (result, err) in
            var isFinal = false
            if let result = result {
                self.transcribedText.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
                self._hasTranscribedText = true
                self.clearBtn.isEnabled = true
                self.copyBtn.isEnabled = self.transcribedText.text.characters.count > 0
            }
            
            if err != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self._isListening = false
                self.copyBtn.isEnabled = self.transcribedText.text.characters.count > 0
                if err != nil {
                    self.setUpInitialState()
                }
            }
            
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat, block: { (buffer, time) in
            self.recognitionRequest?.append(buffer)
        })
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch let err as NSError {
            print("Unable to start audio engine: \(err.debugDescription)")
        }        
    }
    
    @IBAction func copyBtnTapped(_ sender: Any) {
        UIPasteboard.general.string = transcribedText.text
        toast = Toast(text: "Transcribed text copied...", delay: 0, duration: 4)
        toast?.show()
    }
    
    @IBAction func clearBtnTapped(_ sender: Any) {
        setUpInitialState()
    }
    
    private func setUpInitialState() {
        transcribedText.text = "Press button below & speak into your device's microphone. Transcribed text will show up here..."
        _hasTranscribedText = false
        _isListening = false
        clearBtn.isEnabled = _hasTranscribedText
        copyBtn.isEnabled = transcribedText.text.characters.count > 0
        instructionLbl.text = "Tap to transcribe"
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { (status) in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self._authorized = true;
                    self.prepareForListeningAndTranscribing()
                    break;
                case .denied:
                    break;
                case .restricted:
                    break;
                case .notDetermined:
                    break;
                }
            }
        }
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            instructionLbl.text = "Speech recognition not avaialbled on this device"
            playAndTranscribeBtn.isEnabled = false
        }
    }
    
}

