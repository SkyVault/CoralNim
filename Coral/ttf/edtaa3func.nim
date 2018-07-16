import sequtils, math

# Original is taken from freetype-gl

{.push checks: off, stackTrace: off.}

# Compute the local gradient at edge pixels using convolution filters.
# The gradient is computed only at edge pixels. At other places in the
# image, it is never used, and it's mostly zero anyway.
proc computegradient[TFloat](img: openarray[TFloat], w, h: int, gx, gy: var openarray[TFloat]) =
    const SQRT2 = 1.4142136
    for i in 1 ..< h - 1: # Avoid edges where the kernels would spill over
        for j in 1 ..< w - 1:
            let k = i * w + j
            if img[k] > 0 and img[k] < 1: # Compute gradient for edge pixels only
                gx[k] = -img[k-w-1] - SQRT2*img[k-1] - img[k+w-1] + img[k-w+1] + SQRT2*img[k+1] + img[k+w+1]
                gy[k] = -img[k-w-1] - SQRT2*img[k-w] - img[k+w-1] + img[k-w+1] + SQRT2*img[k+w] + img[k+w+1]
                var glength = gx[k]*gx[k] + gy[k]*gy[k]
                if glength > 0: # Avoid division by zero
                    glength = sqrt(glength)
                    gx[k] = gx[k] / glength
                    gy[k] = gy[k] / glength
    # TODO: Compute reasonable values for gx, gy also around the image edges.
    # (These are zero now, which reduces the accuracy for a 1-pixel wide region
    # around the image edge.) 2x2 kernels would be suitable for this.

# A somewhat tricky function to approximate the distance to an edge in a
# certain pixel, with consideration to either the local gradient (gx,gy)
# or the direction to the pixel (dx,dy) and the pixel greyscale value a.
# The latter alternative, using (dx,dy), is the metric used by edtaa2().
# Using a local estimate of the edge gradient (gx,gy) yields much better
# accuracy at and near edges, and reduces the error even at distant pixels
# provided that the gradient direction is accurately estimated.
proc edgedf[TFloat](gx, gy, a: TFloat): TFloat =
    if gx == 0 or gy == 0: # Either A) gx or gv are zero, or B) both
        result = 0.5 - a  # Linear approximation is A) correct or B) a fair guess
    else:
        let glength = sqrt(gx*gx + gy*gy)
        var ggx = gx
        var ggy = gy
        if glength > 0:
            ggx = ggx / glength
            ggy = ggy / glength
        # Everything is symmetric wrt sign and transposition,
        # so move to first octant (ggx>=0, ggy>=0, ggx>=ggy) to
        # avoid handling all possible edge directions.

        ggx = abs(ggx)
        ggy = abs(ggy)
        if ggx < ggy: swap(ggx, ggy)
        let a1 = 0.5 * ggy / ggx
        if a < a1: # 0 <= a < a1
            result = 0.5 * (ggx + ggy) - sqrt(2.0 * ggx * ggy * a)
        elif a < 1 - a1: # a1 <= a <= 1-a1
            result = (0.5 - a) * ggx
        else: # 1-a1 < a <= 1
            result = -0.5 * (ggx + ggy) + sqrt(2.0 * ggx * ggy * (1.0 - a))

proc distaa3[TFloat](img, gximg, gyimg: openarray[TFloat], w, c, xc, yc, xi, yi: int): TFloat =
    let closest = c-xc-yc*w # Index to the edge pixel pointed to from c
    var a = img[closest]    # Grayscale value at the edge pixel
    let gx = gximg[closest] # X gradient component at the edge pixel
    let gy = gyimg[closest] # Y gradient component at the edge pixel

    if a > 1.0: a = 1.0
    if a < 0.0: a = 0.0 # Clip grayscale values outside the range [0,1]
    if a == 0.0: return 1000000.0 # Not an object pixel, return "very far" ("don't know yet")

    let dx = type(img[0])(xi)
    let dy = type(img[0])(yi)
    let di = sqrt(dx*dx + dy*dy) # Length of integer vector, like a traditional EDT
    if di == 0: # Use local gradient only at edges
        # Estimate based on local gradient only
        result = edgedf(gx, gy, a)
    else:
        # Estimate gradient based on direction to edge (accurate for large di)
        result = edgedf(dx, dy, a)
    result = result + di # Same metric as edtaa2, except at edges (where di=0)

proc edtaa3[TFloat](img, gx, gy: openarray[TFloat], w, h: int, distx, disty: var openarray[int16], dist: var openarray[TFloat]) =
    var c : int
    var olddist, newdist: TFloat
    var cdistx, cdisty: int16
    var newdistx, newdisty: int16

    const epsilon = 1e-3

    # Shorthand template: add ubiquitous parameters dist, gx, gy, img and w and call distaa3()
    template DISTAA(c, xc, yc, xi, yi): untyped = distaa3(img, gx, gy, w, c, xc, yc, xi, yi)

    # Initialize index offsets for the current image width
    let offset_u = -w
    let offset_ur = -w + 1
    let offset_r = 1
    let offset_rd = w + 1
    let offset_d = w
    let offset_dl = w-1
    let offset_l = -1
    let offset_lu = -w - 1

    # Initialize the distance images
    let sz = w * h
    for i in 0 ..< sz:
        distx[i] = 0 # At first, all pixels point to
        disty[i] = 0 # themselves as the closest known.
        if img[i] <= 0:
            dist[i]= 1000000 # Big value, means "not set yet"
        elif img[i] < 1:
            dist[i] = edgedf(gx[i], gy[i], img[i]) # Gradient-assisted estimate
        else:
            dist[i]= 0 # Inside the object

    var changed = true

    # Perform the transformation
    while changed: # Sweep until no more updates are made
        changed = false
        # Scan rows, except first row
        var y = 1
        while y < h:
            # move index to leftmost pixel of current row
            var i = y * w
            # scan right, propagate distances from above & left

            # Leftmost pixel is special, has no left neighbors
            olddist = dist[i]
            if olddist > 0: # If non-zero distance or not set yet
                var c = i + offset_u # Index of candidate for testing
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx
                newdisty = cdisty+1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_ur
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx-1
                newdisty = cdisty+1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    changed = true
            inc i

            var x = 1
            # Middle pixels have all neighbors
            while x < w - 1:
                olddist = dist[i]
                if olddist > 0:
                    c = i+offset_l
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx+1
                    newdisty = cdisty
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_lu
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx+1
                    newdisty = cdisty+1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_u
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx
                    newdisty = cdisty+1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_ur
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx-1
                    newdisty = cdisty+1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        changed = true

                inc x
                inc i

            # Rightmost pixel of row is special, has no right neighbors
            olddist = dist[i]
            if olddist > 0: # If not already zero distance
                c = i+offset_l
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx+1
                newdisty = cdisty
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_lu
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx+1
                newdisty = cdisty+1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_u
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx
                newdisty = cdisty+1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    changed = true

            # Move index to second rightmost pixel of current row.
            # Rightmost pixel is skipped, it has no right neighbor.
            i = y*w + w-2

            # scan left, propagate distance from right
            x = w-2
            while x >= 0:
                olddist = dist[i]
                if olddist > 0:
                    let c = i+offset_r
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx-1
                    newdisty = cdisty
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        changed = true
                dec x
                dec i
            inc y

        # Scan rows in reverse order, except last row
        y = h - 2
        while y >= 0:
            # move index to rightmost pixel of current row
            var i = y*w + w-1

            # Scan left, propagate distances from below & right

            # Rightmost pixel is special, has no right neighbors
            olddist = dist[i]
            if olddist > 0: # If not already zero distance
                c = i+offset_d
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx
                newdisty = cdisty-1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_dl
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx+1
                newdisty = cdisty-1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    changed = true
            dec i

            # Middle pixels have all neighbors
            var x = w - 2
            while x > 0:
                olddist = dist[i]
                if olddist > 0:
                    c = i+offset_r
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx-1
                    newdisty = cdisty
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_rd
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx-1
                    newdisty = cdisty-1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_d
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx
                    newdisty = cdisty-1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        olddist=newdist
                        changed = true

                    c = i+offset_dl
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx+1
                    newdisty = cdisty-1
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        changed = true

                dec x
                dec i

            # Leftmost pixel is special, has no left neighbors
            olddist = dist[i]
            if olddist > 0: # If not already zero distance
                c = i+offset_r
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx-1
                newdisty = cdisty
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_rd
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx-1
                newdisty = cdisty-1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    olddist=newdist
                    changed = true

                c = i+offset_d
                cdistx = distx[c]
                cdisty = disty[c]
                newdistx = cdistx
                newdisty = cdisty-1
                newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                if newdist < olddist-epsilon:
                    distx[i]=newdistx
                    disty[i]=newdisty
                    dist[i]=newdist
                    changed = true


            # Move index to second leftmost pixel of current row.
            # Leftmost pixel is skipped, it has no left neighbor.
            i = y*w + 1
            x = 1
            while x < w:
                # scan right, propagate distance from left */
                olddist = dist[i]
                if olddist > 0:
                    c = i+offset_l
                    cdistx = distx[c]
                    cdisty = disty[c]
                    newdistx = cdistx+1
                    newdisty = cdisty
                    newdist = DISTAA(c, cdistx, cdisty, newdistx, newdisty)
                    if newdist < olddist-epsilon:
                        distx[i]=newdistx
                        disty[i]=newdisty
                        dist[i]=newdist
                        changed = true
                inc x
                inc i

            dec y

when defined(js):
    proc newTypedSeq(t: typedesc[float32], sz: int): seq[float32] {.importc: "new Float32Array".}
    proc newTypedSeq(t: typedesc[float64], sz: int): seq[float64] {.importc: "new Float64Array".}
    proc newTypedSeq(t: typedesc[int16], sz: int): seq[int16] {.importc: "new Int16Array".}
    proc newTypedSeq(t: typedesc[int8], sz: int): seq[int8] {.importc: "new Int8Array".}
    proc newTypedSeq(t: typedesc[byte], sz: int): seq[byte] {.importc: "new Uint8Array".}

    template setTypedSeqLen[T](s: var seq[T], sz: int) =
        if s.len < sz: shallowCopy(s, newTypedSeq(type(s[0]), sz))
else:
    template newTypedSeq(T: typedesc, sz: int): untyped = newSeq[T](sz)
    template setTypedSeqLen[T](s: var seq[T], sz: int) = s.setLen(sz)

type DistanceFieldContext*[TFloat] = ref object
    data: seq[TFloat]
    output*: seq[byte]
    xdist: seq[int16]
    ydist: seq[int16]
    gx: seq[TFloat]
    gy: seq[TFloat]
    outside: seq[TFloat]
    inside: seq[TFloat]

proc newDistanceFieldContext*(sz: int = 64 * 32): DistanceFieldContext[float32] =
    result.new()
    let c = result
    shallowCopy c.xdist, newTypedSeq(int16, sz)
    shallowCopy c.ydist, newTypedSeq(int16, sz)
    shallowCopy c.gx, newTypedSeq(float32, sz)
    shallowCopy c.gy, newTypedSeq(float32, sz)
    shallowCopy c.outside, newTypedSeq(float32, sz)
    shallowCopy c.inside, newTypedSeq(float32, sz)

proc resizeBuffers[TFloat](c: DistanceFieldContext[TFloat], sz: int) =
    c.xdist.setTypedSeqLen(sz)
    c.ydist.setTypedSeqLen(sz)
    c.gx.setTypedSeqLen(sz)
    c.gy.setTypedSeqLen(sz)
    c.outside.setTypedSeqLen(sz)
    c.inside.setTypedSeqLen(sz)

proc make_distance_map*[TFloat: SomeReal](c: DistanceFieldContext[TFloat], data: var openarray[TFloat], width, height: int) =
    let sz = (width * height).int

    var img_min = TFloat(255)
    var img_max = TFloat(-255)

    # Convert img into double (data)
    for i in 0 ..< sz:
        let v = data[i]
        if v > img_max: img_max = v
        if v < img_min: img_min = v

    # Rescale image levels between 0 and 1
    for i in 0 ..< sz:
        data[i] = (data[i] - img_min) / img_max

    # Compute outside = edtaa3(bitmap); % Transform background (0's)
    computegradient(data, width, height, c.gx, c.gy)
    edtaa3(data, c.gx, c.gy, width, height, c.xdist, c.ydist, c.outside)

    for i in 0 ..< sz:
        if c.outside[i] < 0:
            c.outside[i] = 0

    # Compute inside = edtaa3(1-bitmap); % Transform foreground (1's)
    c.gx.applyIt(0)
    c.gy.applyIt(0)

    for i in 0 ..< sz: data[i] = 1 - data[i]

    computegradient(data, width, height, c.gx, c.gy)
    edtaa3(data, c.gx, c.gy, width, height, c.xdist, c.ydist, c.inside)

    for i in 0 ..< sz:
        if c.inside[i] < 0:
            c.inside[i] = 0

    # distmap = outside - inside; % Bipolar distance field
    for i in 0 ..< sz:
        var o = c.outside[i]
        o = o - c.inside[i]
        o = 128 + o * 16
        if o < 0: o = 0
        if o > 255: o = 255
        data[i] = o

proc make_distance_map*[TFloat: SomeReal](data: var openarray[TFloat], width, height: int) =
    let sz = (width * height).int
    let ctx = newDistanceFieldContext(sz)
    ctx.make_distance_map(data, width, height)

proc make_distance_map*[TFloat: SomeReal](c: DistanceFieldContext[TFloat], width, height: int) {.inline.} =
    c.make_distance_map(c.data, width, height)

proc make_distance_map*(img: var openarray[byte], width, height : int) =
    let sz = (width * height).int
    let c = newDistanceFieldContext(sz)
    c.data = newTypedSeq(float32, sz)

    # Convert img into double (data)
    for i in 0 ..< sz:
        c.data[i] = type(c.data[i])(img[i])

    make_distance_map(c, width, height)

    # Convert back
    for i in 0 ..< sz:
        img[i] = (255.byte - c.data[i].byte)

proc make_distance_map*[TFloat](c: DistanceFieldContext[TFloat], img: var openarray[byte], x, y, width, height, stride: int, copyBack: bool = true) =
    let sz = (width * height).int
    c.resizeBuffers(sz)
    if c.data.isNil:
        shallowCopy(c.data, newTypedSeq(TFloat, sz))
    else:
        c.data.setTypedSeqLen(sz)

    var i = 0
    # Convert img into double (data)
    for iy in y ..< height + y:
        for ix in x ..< width + x:
            c.data[i] = type(c.data[i])(img[iy * stride + ix])
            inc i

    c.make_distance_map(width, height)

    # Convert back
    i = 0
    if copyBack:
        for iy in y ..< height + y:
            for ix in x ..< width + x:
                img[iy * stride + ix] = (255.byte - c.data[i].byte)
                inc i
    else:
        if c.output.isNil:
            shallowCopy(c.output, newTypedSeq(byte, sz))
        else:
            c.output.setTypedSeqLen(sz)
        for i in 0 ..< sz:
            c.output[i] = (255.byte - c.data[i].byte)

{.pop.}
