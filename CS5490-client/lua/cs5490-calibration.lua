chip.writeRegister(16, 32, 0xfff3e0) -- I DC offset calibration
chip.writeRegister(16, 37, 0xd0000)  -- I AC offset calibration
chip.writeRegister(16, 34, 0xfe6000) -- V DC offset calibration
chip.writeRegister(16, 33, 0x247400) -- current gain calibration for 22Ω resistor pair and 10x scaling: i.e. at 3.3A it will say 0.33
currentScale = 10
