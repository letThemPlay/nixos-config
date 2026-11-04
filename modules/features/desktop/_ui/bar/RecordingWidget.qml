import qs.common
import qs.services

// Only there while recording, as a way to see it's happening and to stop it.
BarItem {
  shown: Recorder.active
  filled: true
  icon: "recording"
  text: Recorder.elapsed
  tint: Theme.danger
  onClicked: Recorder.stop()
}
