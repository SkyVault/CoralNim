type
  Clock* = object
    deltaTime*, framesPerSecond*, timer*: float
    ticks*: int64
    last: float

proc newClock* (): auto =
  result = Clock(
    deltaTime: 0.0,
    framesPerSecond: 0.0,
    timer: 0.0,
    last: 0.0,
    ticks: 0)

proc update* (self: var Clock, now: float)=
  self.deltaTime = (now - self.last)
  self.last = now
  self.framesPerSecond = (if self.deltaTime == 0.0: 0.0 else: (1.0 / self.deltaTime))
  self.timer += self.deltaTime
  inc self.ticks
