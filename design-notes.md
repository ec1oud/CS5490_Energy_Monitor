# Burden Resistors

If one uses a pair of 22Ω resistors for R1 and R2, then for example when
measuring 3.3A RMS with a 1000:1 transformer, the voltage from IIn+ to IIn-
should be 145mV RMS: V = IR, 3.3 / 1000 * 44 = 0.1452.  I measured 140mV with
my voltmeter under such conditions.  The full-scale range is up to 250mV, or
176.78 mV RMS: so with these burden resistors, we won't be able to measure much
more current than that.

So to be able to measure up to 30A for example, it seems the burden resistors
should be 8Ω total, therefore 4Ω each; then 250mV corresponds to 31.25A.  If we
use 3.3Ω instead, we should be able to measure 37.88A peak or 26.78A RMS.

But the CS5490's RMS current register (page 16 address 6) has a range of 0 to
1; so we'll need to calibrate it for a different current range and multiply the
output in the client software.

