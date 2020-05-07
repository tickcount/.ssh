--region dependency: havoc_vector_3_0_0

--region math
function math.round(number, precision)
	local mult = 10 ^ (precision or 0)

	return math.floor(number * mult + 0.5) / mult
end
--endregion

--region angle
--- @class angle_c
--- @field public p number Angle pitch.
--- @field public y number Angle yaw.
--- @field public r number Angle roll.
local angle_c = {}
local angle_mt = {
	__index = angle_c
}

--- Overwrite the angle's angles. Nil values leave the angle unchanged.
--- @param angle angle_c
--- @param p_new number
--- @param y_new number
--- @param r_new number
--- @return void
angle_mt.__call = function(angle, p_new, y_new, r_new)
	p_new = p_new or angle.p
	y_new = y_new or angle.y
	r_new = r_new or angle.r

	angle.p = p_new
	angle.y = y_new
	angle.r = r_new
end

--- Create a new vector object.
--- @param p number
--- @param y number
--- @param r number
--- @return angle_c
local function angle(p, y, r)
	return setmetatable(
		{
			p = p and p or 0,
			y = y and y or 0,
			r = r and r or 0
		},
		angle_mt
	)
end

--- Overwrite the angle's angles. Nil values leave the angle unchanged.
--- @param p number
--- @param y number
--- @param r number
--- @return void
function angle_c:set(p, y, r)
	p = p or self.p
	y = y or self.y
	r = r or self.r

	self.p = p
	self.y = y
	self.r = r
end

--- Offset the angle's angles. Nil values leave the angle unchanged.
--- @param p number
--- @param y number
--- @param r number
--- @return void
function angle_c:offset(p, y, r)
	p = self.p + p or 0
	y = self.y + y or 0
	r = self.r + r or 0

	self.p = self.p + p
	self.y = self.y + y
	self.r = self.r + r
end

--- Clone the angle object.
--- @return angle_c
function angle_c:clone()
	return setmetatable(
		{
			p = self.p,
			y = self.y,
			r = self.r
		},
		angle_mt
	)
end

--- Clone and offset the angle's angles. Nil values leave the angle unchanged.
--- @param p number
--- @param y number
--- @param r number
--- @return angle_c
function angle_c:clone_offset(p, y, r)
	p = self.p + p or 0
	y = self.y + y or 0
	r = self.r + r or 0

	return angle(
		self.p + p,
		self.y + y,
		self.r + r
	)
end

--- Clone the angle and optionally override its coordinates.
--- @param p number
--- @param r number
--- @param r number
--- @return angle_c
function angle_c:clone_set(p, r, r)
	p = p or self.p
	r = r or self.y
	r = r or self.r

	return angle(
		p,
		r,
		r
	)
end

--- Unpack the angle.
--- @return number, number, number
function angle_c:unpack()
	return self.p, self.y, self.r
end

--- Set the angle's euler angles to 0.
--- @return void
function angle_c:nullify()
	self.p = 0
	self.y = 0
	self.r = 0
end

--- Returns a string representation of the angle.
function angle_mt.__tostring(operand_a)
	return string.format("%s, %s, %s", operand_a.p, operand_a.y, operand_a.r)
end

--- Concatenates the angle in a string.
function angle_mt.__concat(operand_a)
	return string.format("%s, %s, %s", operand_a.p, operand_a.y, operand_a.r)
end

--- Adds the angle to another angle.
function angle_mt.__add(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a + operand_b.p,
			operand_a + operand_b.y,
			operand_a + operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p + operand_b,
			operand_a.y + operand_b,
			operand_a.r + operand_b
		)
	end

	return angle(
		operand_a.p + operand_b.p,
		operand_a.y + operand_b.y,
		operand_a.r + operand_b.r
	)
end

--- Subtracts the angle from another angle.
function angle_mt.__sub(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a - operand_b.p,
			operand_a - operand_b.y,
			operand_a - operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p - operand_b,
			operand_a.y - operand_b,
			operand_a.r - operand_b
		)
	end

	return angle(
		operand_a.p - operand_b.p,
		operand_a.y - operand_b.y,
		operand_a.r - operand_b.r
	)
end

--- Multiplies the angle with another angle.
function angle_mt.__mul(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a * operand_b.p,
			operand_a * operand_b.y,
			operand_a * operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p * operand_b,
			operand_a.y * operand_b,
			operand_a.r * operand_b
		)
	end

	return angle(
		operand_a.p * operand_b.p,
		operand_a.y * operand_b.y,
		operand_a.r * operand_b.r
	)
end

--- Divides the angle by the another angle.
function angle_mt.__div(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a / operand_b.p,
			operand_a / operand_b.y,
			operand_a / operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p / operand_b,
			operand_a.y / operand_b,
			operand_a.r / operand_b
		)
	end

	return angle(
		operand_a.p / operand_b.p,
		operand_a.y / operand_b.y,
		operand_a.r / operand_b.r
	)
end

--- Raises the angle to the power of an another angle.
function angle_mt.__pow(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			math.pow(operand_a, operand_b.p),
			math.pow(operand_a, operand_b.y),
			math.pow(operand_a, operand_b.r)
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			math.pow(operand_a.p, operand_b),
			math.pow(operand_a.y, operand_b),
			math.pow(operand_a.r, operand_b)
		)
	end

	return angle(
		math.pow(operand_a.p, operand_b.p),
		math.pow(operand_a.y, operand_b.y),
		math.pow(operand_a.r, operand_b.r)
	)
end

--- Performs modulo on the angle with another angle.
function angle_mt.__mod(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return angle(
			operand_a % operand_b.p,
			operand_a % operand_b.y,
			operand_a % operand_b.r
		)
	end

	if (type(operand_b) == "number") then
		return angle(
			operand_a.p % operand_b,
			operand_a.y % operand_b,
			operand_a.r % operand_b
		)
	end

	return angle(
		operand_a.p % operand_b.p,
		operand_a.y % operand_b.y,
		operand_a.r % operand_b.r
	)
end

--- Perform a unary minus operation on the angle.
function angle_mt.__unm(operand_a)
	return angle(
		-operand_a.p,
		-operand_a.y,
		-operand_a.r
	)
end

--- Clamps the angles to whole numbers. Equivalent to "angle:round" with no precision.
--- @return void
function angle_c:round_zero()
	self.p = math.floor(self.p + 0.5)
	self.y = math.floor(self.y + 0.5)
	self.r = math.floor(self.r + 0.5)
end

--- Round the angles.
--- @param precision number
function angle_c:round(precision)
	self.p = math.round(self.p, precision)
	self.y = math.round(self.y, precision)
	self.r = math.round(self.r, precision)
end

--- Clamps the angles to the nearest base.
--- @param base number
function angle_c:round_base(base)
	self.p = base * math.round(self.p / base)
	self.y = base * math.round(self.y / base)
	self.r = base * math.round(self.r / base)
end

--- Clamps the angles to whole numbers. Equivalent to "angle:round" with no precision.
--- @return angle_c
function angle_c:rounded_zero()
	return angle(
		math.floor(self.p + 0.5),
		math.floor(self.y + 0.5),
		math.floor(self.r + 0.5)
	)
end

--- Round the angles.
--- @param precision number
--- @return angle_c
function angle_c:rounded(precision)
	return angle(
		math.round(self.p, precision),
		math.round(self.y, precision),
		math.round(self.r, precision)
	)
end

--- Clamps the angles to the nearest base.
--- @param base number
--- @return angle_c
function angle_c:rounded_base(base)
	return angle(
		base * math.round(self.p / base),
		base * math.round(self.y / base),
		base * math.round(self.r / base)
	)
end
--endregion

--region vector
--- @class vector_c
--- @field public x number X coordinate.
--- @field public y number Y coordinate.
--- @field public z number Z coordinate.
local vector_c = {}
local vector_mt = {
	__index = vector_c,
}

--- Overwrite the vector's coordinates. Nil will leave coordinates unchanged.
--- @param vector vector_c
--- @param x_new number
--- @param y_new number
--- @param z_new number
--- @return void
vector_mt.__call = function(vector, x_new, y_new, z_new)
	x_new = x_new or vector.x
	y_new = y_new or vector.y
	z_new = z_new or vector.z

	vector.x = x_new
	vector.y = y_new
	vector.z = z_new
end

--- Create a new vector object.
--- @param x number
--- @param y number
--- @param z number
--- @return vector_c
local function vector(x, y, z)
	return setmetatable(
		{
			x = x and x or 0,
			y = y and y or 0,
			z = z and z or 0
		},
		vector_mt
	)
end

--- Overwrite the vector's coordinates. Nil will leave coordinates unchanged.
--- @param x_new number
--- @param y_new number
--- @param z_new number
--- @return void
function vector_c:set(x_new, y_new, z_new)
	x_new = x_new or self.x
	y_new = y_new or self.y
	z_new = z_new or self.z

	self.x = x_new
	self.y = y_new
	self.z = z_new
end

--- Offset the vector's coordinates. Nil will leave the coordinates unchanged.
--- @param x_offset number
--- @param y_offset number
--- @param z_offset number
--- @return void
function vector_c:offset(x_offset, y_offset, z_offset)
	x_offset = x_offset or 0
	y_offset = y_offset or 0
	z_offset = z_offset or 0

	self.x = self.x + x_offset
	self.y = self.y + y_offset
	self.z = self.z + z_offset
end

--- Clone the vector object.
--- @return vector_c
function vector_c:clone()
	return setmetatable(
		{
			x = self.x,
			y = self.y,
			z = self.z
		},
		vector_mt
	)
end

--- Clone the vector object and offset its coordinates. Nil will leave the coordinates unchanged.
--- @param x_offset number
--- @param y_offset number
--- @param z_offset number
--- @return vector_c
function vector_c:clone_offset(x_offset, y_offset, z_offset)
	x_offset = x_offset or 0
	y_offset = y_offset or 0
	z_offset = z_offset or 0

	return setmetatable(
		{
			x = self.x + x_offset,
			y = self.y + y_offset,
			z = self.z + z_offset
		},
		vector_mt
	)
end

--- Clone the vector and optionally override its coordinates.
--- @param x_new number
--- @param y_new number
--- @param z_new number
--- @return vector_c
function vector_c:clone_set(x_new, y_new, z_new)
	x_new = x_new or self.x
	y_new = y_new or self.y
	z_new = z_new or self.z

	return vector(
		x_new,
		y_new,
		z_new
	)
end

--- Unpack the vector.
--- @return number, number, number
function vector_c:unpack()
	return self.x, self.y, self.z
end

--- Set the vector's coordinates to 0.
--- @return void
function vector_c:nullify()
	self.x = 0
	self.y = 0
	self.z = 0
end

--- Returns a string representation of the vector.
function vector_mt.__tostring(operand_a)
	return string.format("%s, %s, %s", operand_a.x, operand_a.y, operand_a.z)
end

--- Concatenates the vector in a string.
function vector_mt.__concat(operand_a)
	return string.format("%s, %s, %s", operand_a.x, operand_a.y, operand_a.z)
end

--- Returns true if the vector's coordinates are equal to another vector.
function vector_mt.__eq(operand_a, operand_b)
	return (operand_a.x == operand_b.x) and (operand_a.y == operand_b.y) and (operand_a.z == operand_b.z)
end

--- Returns true if the vector is less than another vector.
function vector_mt.__lt(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return (operand_a < operand_b.x) or (operand_a < operand_b.y) or (operand_a < operand_b.z)
	end

	if (type(operand_b) == "number") then
		return (operand_a.x < operand_b) or (operand_a.y < operand_b) or (operand_a.z < operand_b)
	end

	return (operand_a.x < operand_b.x) or (operand_a.y < operand_b.y) or (operand_a.z < operand_b.z)
end

--- Returns true if the vector is less than or equal to another vector.
function vector_mt.__le(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return (operand_a <= operand_b.x) or (operand_a <= operand_b.y) or (operand_a <= operand_b.z)
	end

	if (type(operand_b) == "number") then
		return (operand_a.x <= operand_b) or (operand_a.y <= operand_b) or (operand_a.z <= operand_b)
	end

	return (operand_a.x <= operand_b.x) or (operand_a.y <= operand_b.y) or (operand_a.z <= operand_b.z)
end

--- Add a vector to another vector.
function vector_mt.__add(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a + operand_b.x,
			operand_a + operand_b.y,
			operand_a + operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x + operand_b,
			operand_a.y + operand_b,
			operand_a.z + operand_b
		)
	end

	return vector(
		operand_a.x + operand_b.x,
		operand_a.y + operand_b.y,
		operand_a.z + operand_b.z
	)
end

--- Subtract a vector from another vector.
function vector_mt.__sub(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a - operand_b.x,
			operand_a - operand_b.y,
			operand_a - operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x - operand_b,
			operand_a.y - operand_b,
			operand_a.z - operand_b
		)
	end

	return vector(
		operand_a.x - operand_b.x,
		operand_a.y - operand_b.y,
		operand_a.z - operand_b.z
	)
end

--- Multiply a vector with another vector.
function vector_mt.__mul(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a * operand_b.x,
			operand_a * operand_b.y,
			operand_a * operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x * operand_b,
			operand_a.y * operand_b,
			operand_a.z * operand_b
		)
	end

	return vector(
		operand_a.x * operand_b.x,
		operand_a.y * operand_b.y,
		operand_a.z * operand_b.z
	)
end

--- Divide a vector by another vector.
function vector_mt.__div(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a / operand_b.x,
			operand_a / operand_b.y,
			operand_a / operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x / operand_b,
			operand_a.y / operand_b,
			operand_a.z / operand_b
		)
	end

	return vector(
		operand_a.x / operand_b.x,
		operand_a.y / operand_b.y,
		operand_a.z / operand_b.z
	)
end

--- Raised a vector to the power of another vector.
function vector_mt.__pow(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			math.pow(operand_a, operand_b.x),
			math.pow(operand_a, operand_b.y),
			math.pow(operand_a, operand_b.z)
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			math.pow(operand_a.x, operand_b),
			math.pow(operand_a.y, operand_b),
			math.pow(operand_a.z, operand_b)
		)
	end

	return vector(
		math.pow(operand_a.x, operand_b.x),
		math.pow(operand_a.y, operand_b.y),
		math.pow(operand_a.z, operand_b.z)
	)
end

--- Performs a modulo operation on a vector with another vector.
function vector_mt.__mod(operand_a, operand_b)
	if (type(operand_a) == "number") then
		return vector(
			operand_a % operand_b.x,
			operand_a % operand_b.y,
			operand_a % operand_b.z
		)
	end

	if (type(operand_b) == "number") then
		return vector(
			operand_a.x % operand_b,
			operand_a.y % operand_b,
			operand_a.z % operand_b
		)
	end

	return vector(
		operand_a.x % operand_b.x,
		operand_a.y % operand_b.y,
		operand_a.z % operand_b.z
	)
end

--- Perform a unary minus operation on the vector.
function vector_mt.__unm(operand_a)
	return vector(
		-operand_a.x,
		-operand_a.y,
		-operand_a.z
	)
end

--- Returns the vector's 2 dimensional length squared.
--- @return number
function vector_c:length2_squared()
	return (self.x * self.x) + (self.y * self.y);
end

--- Return's the vector's 2 dimensional length.
--- @return number
function vector_c:length2()
	return math.sqrt(self:length2_squared())
end

--- Returns the vector's 3 dimensional length squared.
--- @return number
function vector_c:length_squared()
	return (self.x * self.x) + (self.y * self.y) + (self.z * self.z);
end

--- Return's the vector's 3 dimensional length.
--- @return number
function vector_c:length()
	return math.sqrt(self:length_squared())
end

--- Returns the vector's dot product.
--- @param b vector_c
--- @return number
function vector_c:dot_product(b)
	return (self.x * b.x) + (self.y * b.y) + (self.z * b.z)
end

--- Returns the vector's cross product.
--- @param b vector_c
--- @return vector_c
function vector_c:cross_product(b)
	return vector(
		(self.y * b.z) - (self.z * b.y),
		(self.z * b.x) - (self.x * b.z),
		(self.x * b.y) - (self.y * b.x)
	)
end

--- Returns the 2 dimensional distance between the vector and another vector.
--- @param destination vector_c
--- @return number
function vector_c:distance2(destination)
	return (destination - self):length2()
end

--- Returns the 3 dimensional distance between the vector and another vector.
--- @param destination vector_c
--- @return number
function vector_c:distance(destination)
	return (destination - self):length()
end

--- Returns the distance on the X axis between the vector and another vector.
--- @param destination vector_c
--- @return number
function vector_c:distance_x(destination)
	return math.abs(self.x - destination.x)
end

--- Returns the distance on the Y axis between the vector and another vector.
--- @param destination vector_c
--- @return number
function vector_c:distance_y(destination)
	return math.abs(self.y - destination.y)
end

--- Returns the distance on the Z axis between the vector and another vector.
--- @param destination vector_c
--- @return number
function vector_c:distance_z(destination)
	return math.abs(self.z - destination.z)
end

--- Returns true if the vector is within the given distance to another vector.
--- @param destination vector_c
--- @param distance number
--- @return boolean
function vector_c:in_range(destination, distance)
	return self:distance(destination) <= distance
end

--- Clamps the vector's coordinates to whole numbers. Equivalent to "vector:round" with no precision.
--- @return void
function vector_c:round_zero()
	self.x = math.floor(self.x + 0.5)
	self.y = math.floor(self.y + 0.5)
	self.z = math.floor(self.z + 0.5)
end

--- Round the vector's coordinates.
--- @param precision number
--- @return void
function vector_c:round(precision)
	self.x = math.round(self.x, precision)
	self.y = math.round(self.y, precision)
	self.z = math.round(self.z, precision)
end

--- Clamps the vector's coordinates to the nearest base.
--- @param base number
--- @return void
function vector_c:round_base(base)
	self.x = base * math.round(self.x / base)
	self.y = base * math.round(self.y / base)
	self.z = base * math.round(self.z / base)
end

--- Clamps the vector's coordinates to whole numbers. Equivalent to "vector:round" with no precision.
--- @return vector_c
function vector_c:rounded_zero()
	return vector(
		math.floor(self.x + 0.5),
		math.floor(self.y + 0.5),
		math.floor(self.z + 0.5)
	)
end

--- Round the vector's coordinates.
--- @param precision number
--- @return vector_c
function vector_c:rounded(precision)
	return vector(
		math.round(self.x, precision),
		math.round(self.y, precision),
		math.round(self.z, precision)
	)
end

--- Clamps the vector's coordinates to the nearest base.
--- @param base number
--- @return vector_c
function vector_c:rounded_base(base)
	return vector(
		base * math.round(self.x / base),
		base * math.round(self.y / base),
		base * math.round(self.z / base)
	)
end

--- Normalize the vector.
--- @return void
function vector_c:normalize()
	local length = self:length()

	-- Prevent possible divide-by-zero errors.
	if (length ~= 0) then
		self.x = self.x / length
		self.y = self.y / length
		self.z = self.z / length
	else
		self.x = 0
		self.y = 0
		self.z = 1
	end
end

--- Returns the normalized length of a vector.
--- @return number
function vector_c:normalized_length()
	return self:length()
end

--- Returns a copy of the vector, normalized.
--- @return vector_c
function vector_c:normalized()
	local length = self:length()

	if (length ~= 0) then
		return vector(
			self.x / length,
			self.y / length,
			self.z / length
		)
	else
		return vector(0, 0, 1)
	end
end

--- Returns a new 2 dimensional vector of the original vector when mapped to the screen, or nil if the vector is off-screen.
--- @return vector_c
function vector_c:to_screen(only_within_screen_boundary)
	local x, y = renderer.world_to_screen(self.x, self.y, self.z)

	if (x == nil or y == nil) then
		return nil
	end

	if (only_within_screen_boundary == true) then
		local screen_x, screen_y = client.screen_size()

		if (x < 0 or x > screen_x or y < 0 or y > screen_y) then
			return nil
		end
	end

	return vector(x, y)
end

--- Returns the magnitude of the vector, use this to determine the speed of the vector if it's a velocity vector.
--- @return number
function vector_c:magnitude()
	return math.sqrt(
		math.pow(self.x, 2) +
			math.pow(self.y, 2) +
			math.pow(self.z, 2)
	)
end

--- Returns the angle of the vector in regards to another vector.
--- @param destination vector_c
--- @return angle_c
function vector_c:angle_to(destination)
	-- Calculate the delta of vectors.
	local delta_vector = vector(destination.x - self.x, destination.y - self.y, destination.z - self.z)

	-- Calculate the yaw.
	local yaw = math.deg(math.atan2(delta_vector.y, delta_vector.x))

	-- Calculate the pitch.
	local hyp = math.sqrt(delta_vector.x * delta_vector.x + delta_vector.y * delta_vector.y)
	local pitch = math.deg(math.atan2(-delta_vector.z, hyp))

	return angle(pitch, yaw)
end

--- Lerp to another vector.
--- @param destination vector_c
--- @param percentage number
--- @return vector_c
function vector_c:lerp(destination, percentage)
	return self + (destination - self) * percentage
end

--- Internally divide a ray.
--- @param source vector_c
--- @param destination vector_c
--- @param m number
--- @param n number
--- @return vector_c
local function vector_internal_division(source, destination, m, n)
	return vector((source.x * n + destination.x * m) / (m + n),
		(source.y * n + destination.y * m) / (m + n),
		(source.z * n + destination.z * m) / (m + n))
end

--- Returns the result of client.trace_line between two vectors.
--- @param destination vector_c
--- @param skip_entindex number
--- @return number, number|nil
function vector_c:trace_line_to(destination, skip_entindex)
	skip_entindex = skip_entindex or -1

	return client.trace_line(
		skip_entindex,
		self.x,
		self.y,
		self.z,
		destination.x,
		destination.y,
		destination.z
	)
end

--- Trace line to another vector and returns the fraction, entity, and the impact point.
--- @param destination vector_c
--- @param skip_entindex number
--- @return number, number, vector_c
function vector_c:trace_line_impact(destination, skip_entindex)
	skip_entindex = skip_entindex or -1

	local fraction, eid = client.trace_line(skip_entindex, self.x, self.y, self.z, destination.x, destination.y, destination.z)
	local impact = self:lerp(destination, fraction)

	return fraction, eid, impact
end

--- Trace line to another vector, skipping any entity indices returned by the callback and returns the fraction, entity, and the impact point.
--- @param destination vector_c
--- @param callback fun(eid: number): boolean
--- @param max_traces number
--- @return number, number, vector_c
function vector_c:trace_line_skip_indices(destination, max_traces, callback)
	max_traces = max_traces or 10

	local fraction, eid = 0, -1
	local impact = self
	local i = 0

	while (max_traces >= i and fraction < 1 and ((eid > -1 and callback(eid)) or impact == self)) do
		fraction, eid, impact = impact:trace_line_impact(destination, eid)
		i = i + 1
	end

	return self:distance(impact) / self:distance(destination), eid, impact
end

--- Traces a line from source to destination and returns the fraction, entity, and the impact point.
--- @param destination vector_c
--- @param skip_entindex table
--- @param skip_distance number
--- @return number, number
function vector_c:trace_line_skip_class(destination, skip_entindex, skip_distance)
	local should_skip = function(index, skip_entity)
		local class_name = entity.get_classname(index) or ""
		for i in 1, #skip_entity do
			if class_name == skip_entity[i] then
				return true
			end
		end

		return false
	end

	local angles = self:angle_to(destination)
	local direction = angles:to_forward_vector()

	local last_traced_position = self

	while true do  -- Start tracing.
		local fraction, hit_entity = last_traced_position:trace_line_to(destination)

		if fraction == 1 and hit_entity == -1 then  -- If we didn't hit anything.
			return 1, -1  -- return nothing.
		else  -- BOIS WE HIT SOMETHING.
			if should_skip(hit_entity, skip_entindex) then  -- If entity should be skipped.
				-- Set last traced position according to fraction.
				last_traced_position = vector_internal_division(self, destination, fraction, 1 - fraction)

				-- Add a little gap per each trace to prevent inf loop caused by intersection.
				last_traced_position = last_traced_position + direction * skip_distance
			else  -- That's the one I want.
				return fraction, hit_entity, self:lerp(destination, fraction)
			end
		end
	end
end

--- Returns the result of client.trace_bullet between two vectors.
--- @param eid number
--- @param destination vector_c
--- @return number|nil, number
function vector_c:trace_bullet_to(destination, eid)
	return client.trace_bullet(
		eid,
		self.x,
		self.y,
		self.z,
		destination.x,
		destination.y,
		destination.z
	)
end

--- Returns the vector of the closest point along a ray.
--- @param ray_start vector_c
--- @param ray_end vector_c
--- @return vector_c
function vector_c:closest_ray_point(ray_start, ray_end)
	local to = self - ray_start
	local direction = ray_end - ray_start
	local length = direction:length()

	direction:normalize()

	local ray_along = to:dot_product(direction)

	if (ray_along < 0) then
		return ray_start
	elseif (ray_along > length) then
		return ray_end
	end

	return ray_start + direction * ray_along
end

--- Returns a point along a ray after dividing it.
--- @param ray_end vector_c
--- @param ratio number
--- @return vector_c
function vector_c:ray_divided(ray_end, ratio)
	return (self * ratio + ray_end) / (1 + ratio)
end

--- Returns a ray divided into a number of segments.
--- @param ray_end vector_c
--- @param segments number
--- @return table<number, vector_c>
function vector_c:ray_segmented(ray_end, segments)
	local points = {}

	for i = 0, segments do
		points[i] = vector_internal_division(self, ray_end, i, segments - i)
	end

	return points
end

--- Returns the best source vector and destination vector to draw a line on-screen using world-to-screen.
--- @param ray_end vector_c
--- @param total_segments number
--- @return vector_c|nil, vector_c|nil
function vector_c:ray(ray_end, total_segments)
	total_segments = total_segments or 128

	local segments = {}
	local step = self:distance(ray_end) / total_segments
	local angle = self:angle_to(ray_end)
	local direction = angle:to_forward_vector()

	for i = 1, total_segments do
		table.insert(segments, self + (direction * (step * i)))
	end

	local src_screen_position = vector(0, 0, 0)
	local dst_screen_position = vector(0, 0, 0)
	local src_in_screen = false
	local dst_in_screen = false

	for i = 1, #segments do
		src_screen_position = segments[i]:to_screen()

		if src_screen_position ~= nil then
			src_in_screen = true

			break
		end
	end

	for i = #segments, 1, -1 do
		dst_screen_position = segments[i]:to_screen()

		if dst_screen_position ~= nil then
			dst_in_screen = true

			break
		end
	end

	if src_in_screen and dst_in_screen then
		return src_screen_position, dst_screen_position
	end

	return nil
end

--- Returns true if the ray goes through a smoke. False if not.
--- @param ray_end vector_c
--- @return boolean
function vector_c:ray_intersects_smoke(ray_end)
	return line_goes_through_smoke(self.x, self.y, self.z, ray_end.x, ray_end.y, ray_end.z, 1)
end

--- Returns true if the vector lies within the boundaries of a given 2D polygon. The polygon is a table of vectors. The Z axis is ignored.
--- @param polygon table<any, vector_c>
--- @return boolean
function vector_c:inside_polygon2(polygon)
	local odd_nodes = false
	local polygon_vertices = #polygon
	local j = polygon_vertices

	for i = 1, polygon_vertices do
		if (polygon[i].y < self.y and polygon[j].y >= self.y or polygon[j].y < self.y and polygon[i].y >= self.y) then
			if (polygon[i].x + (self.y - polygon[i].y) / (polygon[j].y - polygon[i].y) * (polygon[j].x - polygon[i].x) < self.x) then
				odd_nodes = not odd_nodes
			end
		end

		j = i
	end

	return odd_nodes
end

--- Draws a world circle with an origin of the vector. Code credited to sapphyrus.
--- @param radius number
--- @param r number
--- @param g number
--- @param b number
--- @param a number
--- @param accuracy number
--- @param width number
--- @param outline number
--- @param start_degrees number
--- @param percentage number
--- @return void
function vector_c:draw_circle(radius, r, g, b, a, accuracy, width, outline, start_degrees, percentage)
	local accuracy = accuracy ~= nil and accuracy or 3
	local width = width ~= nil and width or 1
	local outline = outline ~= nil and outline or false
	local start_degrees = start_degrees ~= nil and start_degrees or 0
	local percentage = percentage ~= nil and percentage or 1

	local screen_x_line_old, screen_y_line_old

	for rot = start_degrees, percentage * 360, accuracy do
		local rot_temp = math.rad(rot)
		local lineX, lineY, lineZ = radius * math.cos(rot_temp) + self.x, radius * math.sin(rot_temp) + self.y, self.z
		local screen_x_line, screen_y_line = renderer.world_to_screen(lineX, lineY, lineZ)
		if screen_x_line ~= nil and screen_x_line_old ~= nil then

			for i = 1, width do
				local i = i - 1

				renderer.line(screen_x_line, screen_y_line - i, screen_x_line_old, screen_y_line_old - i, r, g, b, a)
			end

			if outline then
				local outline_a = a / 255 * 160

				renderer.line(screen_x_line, screen_y_line - width, screen_x_line_old, screen_y_line_old - width, 16, 16, 16, outline_a)

				renderer.line(screen_x_line, screen_y_line + 1, screen_x_line_old, screen_y_line_old + 1, 16, 16, 16, outline_a)
			end
		end

		screen_x_line_old, screen_y_line_old = screen_x_line, screen_y_line
	end
end

--- Performs math.min on the vector.
--- @param value number
--- @return void
function vector_c:min(value)
	self.x = math.min(value, self.x)
	self.y = math.min(value, self.y)
	self.z = math.min(value, self.z)
end

--- Performs math.max on the vector.
--- @param value number
--- @return void
function vector_c:max(value)
	self.x = math.max(value, self.x)
	self.y = math.max(value, self.y)
	self.z = math.max(value, self.z)
end

--- Performs math.min on the vector and returns the result.
--- @param value number
--- @return void
function vector_c:minned(value)
	return vector(
		math.min(value, self.x),
		math.min(value, self.y),
		math.min(value, self.z)
	)
end

--- Performs math.max on the vector and returns the result.
--- @param value number
--- @return void
function vector_c:maxed(value)
	return vector(
		math.max(value, self.x),
		math.max(value, self.y),
		math.max(value, self.z)
	)
end
--endregion

--region angle_vector_methods
--- Returns a forward vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_forward_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))

	return vector(cp * cy, cp * sy, -sp)
end

--- Return an up vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_up_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))

	return vector(cr * sp * cy + sr * sy, cr * sp * sy + sr * cy * -1, cr * cp)
end

--- Return a right vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_right_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))

	return vector(sr * sp * cy * -1 + cr * sy, sr * sp * sy * -1 + -1 * cr * cy, -1 * sr * cp)
end

--- Return a backward vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_backward_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))

	return -vector(cp * cy, cp * sy, -sp)
end

--- Return a left vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_left_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))

	return -vector(sr * sp * cy * -1 + cr * sy, sr * sp * sy * -1 + -1 * cr * cy, -1 * sr * cp)
end

--- Return a down vector of the angle. Use this to convert an angle into a cartesian direction.
--- @return vector_c
function angle_c:to_down_vector()
	local degrees_to_radians = function(degrees)
		return degrees * math.pi / 180
	end

	local sp = math.sin(degrees_to_radians(self.p))
	local cp = math.cos(degrees_to_radians(self.p))
	local sy = math.sin(degrees_to_radians(self.y))
	local cy = math.cos(degrees_to_radians(self.y))
	local sr = math.sin(degrees_to_radians(self.r))
	local cr = math.cos(degrees_to_radians(self.r))

	return -vector(cr * sp * cy + sr * sy, cr * sp * sy + sr * cy * -1, cr * cp)
end

--- Calculate where a vector is in a given field of view.
--- @param source vector_c
--- @param destination vector_c
--- @return number
function angle_c:fov_to(source, destination)
	local fwd = self:to_forward_vector()
	local delta = (destination - source):normalized()
	local fov = math.acos(fwd:dot_product(delta) / delta:length())

	return math.max(0.0, math.deg(fov))
end

--- Returns the degrees bearing of the angle's yaw.
--- @param precision number
--- @return number
function angle_c:bearing(precision)
	local yaw = 180 - self.y + 90
	local degrees = (yaw % 360 + 360) % 360

	degrees = degrees > 180 and degrees - 360 or degrees

	return math.round(degrees + 180, precision)
end

--- Returns the yaw appropriate for renderer circle's start degrees.
--- @return number
function angle_c:start_degrees()
	local yaw = self.y
	local degrees = (yaw % 360 + 360) % 360

	degrees = degrees > 180 and degrees - 360 or degrees

	return degrees + 180
end

--- Returns a copy of the angles normalized and clamped.
--- @return number
function angle_c:normalize()
	local pitch = self.p

	if (pitch < -89) then
		pitch = -89
	elseif (pitch > 89) then
		pitch = 89
	end

	local yaw = self.y

	while yaw > 180 do
		yaw = yaw - 360
	end

	while yaw < -180 do
		yaw = yaw + 360
	end

	return angle(pitch, yaw, 0)
end

--- Normalizes and clamps the angles.
--- @return number
function angle_c:normalized()
	if (self.p < -89) then
		self.p = -89
	elseif (self.p > 89) then
		self.p = 89
	end

	local yaw = self.y

	while yaw > 180 do
		yaw = yaw - 360
	end

	while yaw < -180 do
		yaw = yaw + 360
	end

	self.y = yaw
	self.r = 0
end
--endregion

--region functions
--- Draws a polygon to the screen.
--- @param polygon table<number, vector_c>
--- @return void
function vector_c.draw_polygon(polygon, r, g, b, a, segments)
	for id, vertex in pairs(polygon) do
		local next_vertex = polygon[id + 1]

		if (next_vertex == nil) then
			next_vertex = polygon[1]
		end

		local ray_a, ray_b = vertex:ray(next_vertex, (segments or 64))

		if (ray_a ~= nil and ray_b ~= nil) then
			renderer.line(
				ray_a.x, ray_a.y,
				ray_b.x, ray_b.y,
				r, g, b, a
			)
		end
	end
end

--- Returns the eye position of a player.
--- @param eid number
--- @return vector_c
function vector_c.eye_position(eid)
	local origin = vector(entity.get_prop(eid, "m_vecOrigin", 3))
	local _, _, view_z = entity.get_prop(eid, "m_vecViewOffset")
	local duck_amount = entity.get_prop(eid, "m_flDuckAmount")

	origin.z = origin.z + view_z - duck_amount * 16

	return origin
end
--endregion
--endregion

local M = {}

local table_insert, table_concat, string_rep, string_len, string_sub = table.insert, table.concat, string.rep, string.len, string.sub
local math_max, math_floor, math_ceil = math.max, math.floor, math.ceil

local function len(str)
	local _, count = string.gsub(tostring(str), "[^\128-\193]", "")
	return count
end

local styles = {
	--					 1    2     3    4    5     6    7    8     9    10   11
	["ASCII"] = {"-", "|", "+"},
	["Compact"] = {"-", " ", " ", " ", " ", " ", " ", " "},
	["ASCII (Girder)"] = {"=", "||",  "//", "[]", "\\\\",  "|]", "[]", "[|",  "\\\\", "[]", "//"},
	["Unicode"] = {"═", "║",  "╔", "╦", "╗",  "╠", "╬", "╣",  "╚", "╩", "╝"},
	["Unicode (Single Line)"] = {"─", "│",  "┌", "┬", "┐",  "├", "┼", "┤",  "└", "┴", "┘"},
	["Markdown (Github)"] = {"-", "|", "|"}
}

--initialize missing style values (ascii etc)
for _, style in pairs(styles) do
	if #style == 3 then
		for j=4, 11 do
			style[j] = style[3]
		end
	end
end

local function justify_center(text, width)
	text = string_sub(text, 1, width)
	local length = len(text)
	return string_rep(" ", math_floor(width/2-length/2)) .. text .. string_rep(" ", math_ceil(width/2-length/2))
end

local function justify_left(text, width)
	text = string_sub(text, 1, width)
	return text .. string_rep(" ", width-len(text))
end

function M.generate_table(rows, headings, options)
	if type(options) == "string" or options == nil then
		options = {
			style=options or "ASCII",
		}
	end

	if options.top_line == nil then
		options.top_line = options.style ~= "Markdown (Github)"
	end

	if options.bottom_line == nil then
		options.bottom_line = options.style ~= "Markdown (Github)"
	end

	if options.header_seperator_line == nil then
		options.header_seperator_line = true
	end

	local seperators = styles[options.style] or styles["ASCII"]

	local rows_out, columns_width, columns_count = {}, {}, 0
	local has_headings = headings ~= nil and #headings > 0

	if has_headings then
		for i=1, #headings do
			columns_width[i] = len(headings[i])+2
		end
		columns_count = #headings
	else
		for i=1, #rows do
			columns_count = math_max(columns_count, #rows[i])
		end
	end

	for i=1, #rows do
		local row = rows[i]
		for c=1, columns_count do
			columns_width[c] = math_max(columns_width[c] or 2, len(row[c])+2)
		end
	end

	local column_seperator_rows = {}
	for i=1, columns_count do
		table_insert(column_seperator_rows, string_rep(seperators[1], columns_width[i]))
	end
	if options.top_line then
		table_insert(rows_out, seperators[3] .. table_concat(column_seperator_rows, seperators[4]) .. seperators[5])
	end

	if has_headings then
		local headings_justified = {}
		for i=1, columns_count do
			headings_justified[i] = justify_center(headings[i], columns_width[i])
		end
		table_insert(rows_out, seperators[2] .. table_concat(headings_justified, seperators[2]) .. seperators[2])
		if options.header_seperator_line then
			table_insert(rows_out, seperators[6] .. table_concat(column_seperator_rows, seperators[7]) .. seperators[8])
		end
	end

	for i=1, #rows do
		local row, row_out = rows[i], {}
		if #row == 0 then
			table_insert(rows_out, seperators[6] .. table_concat(column_seperator_rows, seperators[7]) .. seperators[8])
		else
			for j=1, columns_count do
				local justified = options.value_justify == "center" and justify_center(row[j] or "", columns_width[j]-2) or justify_left(row[j] or "", columns_width[j]-2)
				row_out[j] = " " .. justified .. " "
			end
			table_insert(rows_out, seperators[2] .. table_concat(row_out, seperators[2]) .. seperators[2])
		end
	end

	if options.bottom_line and seperators[9] then
		table_insert(rows_out, seperators[9] .. table_concat(column_seperator_rows, seperators[10]) .. seperators[11])
	end

	return table_concat(rows_out, "\n")
end

local table_gen = setmetatable(M, {
	__call = function(_, ...)
		return M.generate_table(...)
	end
})

local get_script_name = function()
	local funca, err = pcall(function() GS_THROW_ERROR() end)
	return (not funca and err:match("\\(.*):(.*):") or nil)
end

local debug_print = function(text)
	client.color_log(83, 126, 242, string.format("[%s]\0", get_script_name()))
	client.color_log(163, 163, 163, " ", text)
end

local debug_count = function(tab)
	local count = 0

	for _, _ in pairs(tab) do
		count = count + 1
	end

	return count
end

-- SCRIPT REGION
if package.plugin_tbc ~= nil then
	client.color_log(255, 0, 0, ' - \0')
	client.color_log(255, 255, 255, 'Failed to load \0')
	client.color_log(0, 255, 255, 'Tickbase controller \0')
	client.color_log(255, 0, 0, '[script is already active]')
	error()
end

local script = {
	version = 'v2.0.8 beta',
	debug = false,

	reference = { },
	interface = {
		ui.new_checkbox('AA', 'Other', 'Shot shift handler'),
		ui.new_checkbox('AA', 'Other', 'Refine shot'),
		ui.new_combobox('AA', 'Other', 'Lower body mode', { 'Movement', 'Opposite' })
	}
}

function script:ui(name)
	local define = self.reference[name]

    if define == nil then
        error(string.format('unknown reference %s', name))
    end

    return {
        get_ids = function() return define[1] end,
        get_reffer = function() return define[2] end,

        call = function()
            local list = { }

            for i=1, #define[1] do
                list[#list+1] = ui.get(define[1][i])
            end

            return unpack(list)
        end,

        set = function(_, value, index, ignore_errors)
            local index = index or 1
            return ignore_errors == true and ({ pcall(ui.set, define[1][index], value) })[1] or ui.set(define[1][index], value)
        end,

        set_cache = function(_, index, should_call, var)
			local index = index or 1
			
			if package._gcache == nil then
				package._gcache = { }
			end

            local name, _cond = 
                tostring(define[1][index]), 
                ui.get(define[1][index])

            local _type = type(_cond)
            local _, mode = ui.get(define[1][index])
            local finder = mode or (_type == 'boolean' and tostring(_cond) or _cond)

            package._gcache[name] = package._gcache[name] or finder
        
            local hotkey_modes = { [0] = 'always on', [1] = 'on hotkey', [2] = 'toggle', [3] = 'off hotkey' }

            if should_call then ui.set(define[1][index], mode ~= nil and hotkey_modes[var] or var) else
                if package._gcache[name] ~= nil then
                    local _cache = package._gcache[name]
                    
                    if _type == 'boolean' then
                        if _cache == 'true' then _cache = true end
                        if _cache == 'false' then _cache = false end
                    end
        
                    ui.set(define[1][index], mode ~= nil and hotkey_modes[_cache] or _cache)
                    package._gcache[name] = nil
                end
            end
        end,

        set_visible = function(_, value, index)
            local index = index or 1

            ui.set_visible(define[1][index], value)
        end,
    }
end

function script:ui_register(name, pdata)
    local ref_list = { }
    local ids = { pcall(ui.reference, unpack(pdata)) }

    if ids[1] == false then
        error(string.format('%s cannot be defined (%s)', name, ids[2]))
    end

    if self.reference[name] ~= nil then
        error(string.format('%s is already taken in metatable', name))
    end

    for i=2, #ids do
        ref_list[#ref_list+1] = ids[i]
    end
    
    self.reference[name] = { ref_list, pdata }

    return self:ui(name)
end

local notes_pos = function(b)
    local c=function(d,e)
        local f={}
        for g in pairs(d) do 
            table.insert(f,g)
        end;
        table.sort(f,e)
        local h=0;
        local i=function()
            h=h+1;
            if f[h]==nil then 
                return nil 
            else 
                return f[h],d[f[h]]
            end 
        end;
        return i 
    end;
    
    local j={
        get=function(k)
            local l,m=0,{}
            for n,o in c(package.cnotes) do 
                if o==true then 
                    l=l+1;m[#m+1]={n,l}
                end 
            end;
            for p=1,#m do 
                if m[p][1]==b then 
                    return k(m[p][2]-1)
                end 
            end 
        end,
        
        set_state=function(q)
            package.cnotes[b]=q;
            table.sort(package.cnotes)
        end,
        unset=function()
            client.unset_event_callback('shutdown',callback)
        end
    }
    
    client.set_event_callback('shutdown',function()
        if package.cnotes[b]~=nil then package.cnotes[b]=nil end
    end)
    
    if package.cnotes==nil then 
        package.cnotes={}
    end;

    return j 
end

local initialization = function()
	local note = notes_pos 'b_tbc.v2'
	
	package.plugin_tbc = true

	-- Cheat references
	-- local autofire = script:ui_register('autofire', { 'RAGE', 'Aimbot', 'Automatic fire' })
	local hitchance = script:ui_register('hitchance', { 'RAGE', 'Aimbot', 'Minimum hit chance' })

    local dt_reserve = script:ui_register('dt_reserve', { 'MISC', 'Settings', 'Double tap reserve' })
    local usrcmd_maxpticks = script:ui_register('usrcmd_maxpticks', { 'MISC', 'Settings', 'sv_maxusrcmdprocessticks' })
    local hold_aim = script:ui_register('hold_aim', { 'MISC', 'Settings', 'sv_maxusrcmdprocessticks_holdaim' })

    local double_tap = script:ui_register('double_tap', { 'RAGE', 'Other', 'Double tap' })
    local double_tap_mode = script:ui_register('double_tap_mode', { 'RAGE', 'Other', 'Double tap mode' })
    local onshot_aa = script:ui_register('onshot_aa', { 'AA', 'Other', 'On shot anti-aim' })

	local bodyyaw = script:ui_register('bodyyaw', { 'AA', 'Anti-aimbot angles', 'Body yaw' })
    local lowerbody = script:ui_register('lowerbody', { 'AA', 'Anti-aimbot angles', 'Lower body yaw target' })

    -- Plugin references
	local master_switch = script:ui_register('master_switch', { 'AA', 'Other', 'Shot shift handler' })
	local refine_shot = script:ui_register('refine_shot', { 'AA', 'Other', 'Refine shot' })
	local tbc_lowerbody = script:ui_register('tbc_lowerbody', { 'AA', 'Other', 'Lower body mode' })

    -- COMMAND REGION
    local cmove = {
        old_tickbase = 0,
        old_sim_time = 0,
        old_command_num = 0,

        skip_next_differ = false,
        charged_before = false,
    
        did_shift_before = false,
        can_shift_tickbase = 0,

        is_cmd_safe = true,
        last_charge = 0,

		validate_cmd = usrcmd_maxpticks:call(),
		
		lag_state = nil
    }

    local caimbot = {
		data = { },
		shift_time = 0,
		shift_data = { },
    }

    local reset = function()
        if cmove.lag_state ~= nil then
            double_tap:set(cmove.lag_state)
            cmove.lag_state = nil
		end
		
        for i in pairs(script.reference) do
            local element = script:ui(i)

            for j=1, #element:get_ids() do
                element:set_cache(j, false)
            end
        end
    end

    -- DOUBLETAP HANDLER
    local g_doubletap_controller = function(e)
        local next_shift_amount = 0
        local should_break_tbc = false

        local me = entity.get_local_player()
		local wpn = entity.get_player_weapon(me)
		
		local wpn_name = entity.get_classname(wpn) or ''
		local wpn_id = entity.get_prop(wpn, 'm_iItemDefinitionIndex')
		local m_item = wpn_id and bit.band(wpn_id, 0xFFFF) or 0

        local can_exploit = function(me, wpn, ticks_to_shift)
            if wpn == nil then
                return false
            end

            local tickbase = entity.get_prop(me, 'm_nTickBase')
            local curtime = globals.tickinterval() * (tickbase-ticks_to_shift)

            if curtime < entity.get_prop(me, 'm_flNextAttack') then
                return false
            end
        
            if curtime < entity.get_prop(wpn, 'm_flNextPrimaryAttack') then
                return false
            end
        
            return true
        end

        if cmove.validate_cmd > 0 then
            cmove.validate_cmd = cmove.validate_cmd-1

            local dt, dt_key = double_tap:call()

            if dt and dt_key then
                should_break_tbc = true
            end
        end

        double_tap:set_cache(1, should_break_tbc, false)

		::begin_command::
		
        local ready_to_shift = can_exploit(me, wpn, 13)
		local weapon_ready = can_exploit(me, wpn, math.abs(-1 - next_shift_amount))
    
        if ready_to_shift == true or weapon_ready == false and cmove.did_shift_before == true then
            next_shift_amount = 13
        else
            next_shift_amount = 0
        end
	
		local tickbase = entity.get_prop(me, 'm_nTickBase')

        if cmove.old_tickbase ~= 0 and tickbase < cmove.old_tickbase then
            if cmove.old_tickbase-tickbase > 11 then
                cmove.skip_next_differ = true
                cmove.charged_before = false
                cmove.can_shift_tickbase = false
            end
        end

		local difference = e.command_number - cmove.old_command_num

        if difference >= 11 and difference <= usrcmd_maxpticks:call() then
            cmove.can_shift_tickbase = not cmove.skip_next_differ
			cmove.charged_before = cmove.can_shift_tickbase
			cmove.last_charge = difference+1

			cmove.is_cmd_safe = difference > 3 and math.abs(usrcmd_maxpticks:call()-difference) <= 3

			if script.debug then
				debug_print(string.format(
					'shifting tickbase(Δ): %s (%s)', 
					difference+1, cmove.is_cmd_safe and 'safe' or 'unsafe'
				))
			end
        end

        if ready_to_shift == false then
            cmove.can_shift_tickbase = false
        else
            cmove.can_shift_tickbase = cmove.charged_before
        end

        cmove.old_tickbase = tickbase
        cmove.old_command_num = e.command_number

        cmove.skip_next_differ = false
        cmove.did_shift_before = next_shift_amount ~= 0

        cmove.can_shift_tickbase = cmove.can_shift_tickbase and 2 or 0

        if cmove.can_shift_tickbase == 0 and cmove.charged_before == true then
            cmove.can_shift_tickbase = 1
        end

        -- Reset tickbase shift data on doubletap reset
        if cmove.can_shift_tickbase == 0 then
            cmove.last_charge = 0
		end
	end

	-- AIMBOT HANDLER
    local g_aimbot_listener = function(e)
		local run_qm = false
		local is_inactive = caimbot.shift_time == 0

		if double_tap_mode:call() == 'Offensive' and is_inactive and cmove.can_shift_tickbase == 2 then
			caimbot.shift_time = 1
			caimbot.data[debug_count(caimbot.data)+1] = { e.x, e.y, e.z }
			
			run_qm = true
		end

		-- autofire:set_cache(1, run_qm and master_switch:call(), false)
		
		hitchance:set_cache(1, run_qm, 0)
		bodyyaw:set_cache(1, not refine_shot:call() and run_qm, 'Off')
		lowerbody:set_cache(1, run_qm, 'Eye yaw')
	end

	-- CURRENT COMMAND HANDLER
    local g_command_controller = function(e)
        if cmove.lag_state ~= nil then
            double_tap:set(cmove.lag_state)
            cmove.lag_state = nil
		end
		
        local osa, osa_key = onshot_aa:call()
        local dt, dt_key = double_tap:call()

        local cs_tickbase = cmove.can_shift_tickbase

		::begin_command::
		
		local me = entity.get_local_player()

		local losc = dt and dt_key and double_tap_mode:call() == 'Offensive'

		local fired_this_tick = false
		local m_vecvel = { entity.get_prop(me, 'm_vecVelocity') }
		local velocity = math.floor(math.sqrt(m_vecvel[1]^2 + m_vecvel[2]^2 + m_vecvel[3]^2) + 0.5)

		if caimbot.shift_time > 0 then
			local current_command = e
			local reset_command = false

			local max_commands = cmove.last_charge
			local aimbot_command = caimbot.data[debug_count(caimbot.data)]

			if master_switch:call() and debug_count(caimbot.data) > 0 and aimbot_command ~= nil then
				e.in_attack = 1

				local eye_pos = vector(client.eye_position())
				local fire_vector = vector(unpack(aimbot_command))
		
				local entindex, dmg = eye_pos:trace_bullet_to(fire_vector, me, true)
				local aim_at = eye_pos:angle_to(fire_vector)

				if caimbot.shift_time == max_commands or max_commands < 1 then
					e.pitch = aim_at.p
					e.yaw = aim_at.y
					
					if dmg <= 0 then e.in_attack = 0 else
						fired_this_tick = true
						reset_command = true
					end
				end
			end

			caimbot.shift_data[#caimbot.shift_data+1] = {
				caimbot.shift_time, cs_tickbase, e.chokedcommands, entity.get_prop(me, 'm_nTickBase'), globals.tickcount(), 'false'
			}

			if caimbot.shift_time ~= 0 and (reset_command == true or caimbot.shift_time == max_commands or max_commands < 1) then
				if cmove.is_cmd_safe == false or script.debug then
					local fdiff = caimbot.shift_data[1]
					local diff = caimbot.shift_data[#caimbot.shift_data]
					debug_print(string.format('unsafe command(diff %s/%s):\n%s', 
						diff[5]-diff[4], diff[4]-fdiff[4], 
						table_gen(caimbot.shift_data, { 'id', 'shift state', 'choked cmds', 'tbase', 'tcount', 'lag_sent', }, {
							style = "Markdown (Github)"
						})
					))
				end

				caimbot.shift_time = 0
				caimbot.shift_data = { }
				caimbot.data = { }

				-- current_command = e
			else
				caimbot.shift_time = caimbot.shift_time + 1
			end
		end

		if caimbot.shift_time == 0 and fired_this_tick == false and (
			(losc == true and cs_tickbase == 0) or 
			(velocity <= 1 and cs_tickbase == 2)
		) then
			cmove.lag_state = dt

			if debug_count(caimbot.shift_data) > 0 then
				caimbot.shift_data[debug_count(caimbot.shift_data)][6] = tostring(dt)
			end
		end
		
		local lowerbody_state = ({ ['Movement'] = 'Eye yaw', ['Opposite'] = 'Opposite' })[tbc_lowerbody:call()]

		if (osa and osa_key) or velocity > 1 or fired_this_tick == true or caimbot.shift_time > 0 then
			lowerbody_state = 'Eye yaw'
		end

		bodyyaw:set_cache(1, not refine_shot:call() and (caimbot.shift_time > 0 or fired_this_tick), 'Off')
		hitchance:set_cache(1, caimbot.shift_time > 0 or fired_this_tick, 0)
		lowerbody:set(lowerbody_state)

		-- autofire:set_cache(1, not fired_this_tick and (caimbot.shift_time > 0 or reset_command == true), false)

		if cmove.lag_state ~= nil then
			-- e.allow_send_packet = e.chokedcommands >= 3
			double_tap:set(false)
		end
	end

	-- ON RUN COMMAND HANDLER
    local g_command_run = function(e)
        if cmove.lag_state ~= nil then
            double_tap:set(cmove.lag_state)
            cmove.lag_state = nil
		end

		hold_aim:set(true)
		dt_reserve:set_cache(1, true, cmove.is_cmd_safe and 1 or 2)
		usrcmd_maxpticks:set_cache(1, true, 17)
	end

    local g_paint_handler = function()
        note.set_state(false)

        if entity.is_alive(entity.get_local_player()) == false then
            return reset()
        end

        local realtime = globals.realtime() % 3
        local alpha = math.floor(math.sin(realtime * 4) * (255/2-1) + 255/2)
		local success, _, data2 = pcall(ui.reference, 'CONFIG', 'Presets', 'Watermark')

		local dt, dt_key = double_tap:call()

		note.set_state(master_switch:call() and dt and dt_key)
		note.get(function(id)
			-- Δ

			local clr_alpha = 255
			local r, g, b, a = 89, 119, 239, 255

			if success == true then r, g, b, clr_alpha = ui.get(data2) end
            if cmove.is_cmd_safe == false then r, g, b, a = 255, 167, 38, alpha end
            if cmove.can_shift_tickbase < 2 then r, g, b, a = 150, 150, 150, 150 end
    
            local text = string.format('DT [%s] | tickbase(v): %s | state: %s', script.version, cmove.last_charge, cmove.can_shift_tickbase)
            local h, w = 17, renderer.measure_text(nil, text) + 8
            local x, y = client.screen_size(), 10 + (25*id)
    
            x = x - w - 10
    
            renderer.rectangle(x-3, y, 2, h, r, g, b, a)
            renderer.rectangle(x-1, y, w+1, h, 17, 17, 17, clr_alpha)
            renderer.text(x+4, y + 2, 255, 255, 255, 255, '', 0, text)
        end)
	end
	
	client[(script.debug and '' or 'un') .. 'set_event_callback']('weapon_fire', function(c)
		local me = entity.get_local_player()
		local user = client.userid_to_entindex(c.userid)

		if me == user then
			debug_print(string.format('fired at %s (%s)', globals.tickcount(), caimbot.shift_time))
		end
	end)

	client.set_event_callback('predict_command', g_doubletap_controller)
    client.set_event_callback('setup_command', g_command_controller)
    client.set_event_callback('run_command', g_command_run)
    client.set_event_callback('aim_fire', g_aimbot_listener)

    client.set_event_callback('paint_ui', g_paint_handler)
    client.set_event_callback('shutdown', reset)
end

initialization()
