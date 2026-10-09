# Plan: Name Jev and retag the package

## Units

### U1. Say Jev where pub.dev search reads first

The package description in the root pubspec names Laya as the offline multilingual model for
Flutter, names the open-weight alternative to Jev, and stays inside the 60 to 180 character window.
The opening of the root README says that Jev is TypeSafe's hosted API, that Laya is the open-weight
model for that same job, and that this package runs Laya on the device and does not call Jev.

### U2. Spend the five topic slots on topics people already browse

Replace the topic list with machine-learning, on-device-ml, onnx, nlp, and ai, in that order. Do
not add a jev topic.

### U3. Keep the note for the next release and lock the listing

Add one bullet under an Unreleased heading in the changelog. Add a test that fails if the
description drops Jev, leaves the 60 to 180 character window, or the topic list changes, and that
fails if the README drops the Jev, TypeSafe, or open-weight wording.
