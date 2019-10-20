chip.writeRegister(16, 32, 0xfff400) -- I DC offset calibration
chip.writeRegister(16, 37, 0xba000)  -- I AC offset calibration
chip.writeRegister(16, 34, 0xfe6000) -- V DC offset calibration
chip.writeRegister(16, 33, 0x516000) -- current gain calibration for 3.3Ω resistor pair and 30x scaling: i.e. at 3.3A it will say 0.11
currentScale = 30
