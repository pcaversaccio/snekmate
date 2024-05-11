# pragma version ~=0.4.0rc3
"""
@title Elliptic Curve Digital Signature Algorithm (ECDSA) Secp256r1-Based Functions
@custom:contract-name p256
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to verify signatures based on the
        non-Ethereum-native NIST P-256 elliptic curve (also known as
        secp256r1; see https://neuromancer.sk/std/secg/secp256r1). For
        more technical details, please refer to EIP-7212:
        https://eips.ethereum.org/EIPS/eip-7212.
        The implementation is inspired by dcposch's and nalinbhardwaj's
        implementation here:
        https://github.com/daimo-eth/p256-verifier/blob/master/src/P256Verifier.sol.
"""


# @notice All of the constant values defined subsequently are
# parameters for the elliptical curve secp256r1 (see the standard
# curve database: https://neuromancer.sk/std/secg/secp256r1).


# @dev Curve prime field modulus.
p: constant(uint256) = 115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_951


# @dev Short Weierstrass first coefficient.
# @notice The assumption "a == -3 (mod p)" is used throughout
# the codebase.
a: constant(uint256) = 115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_948
# @dev Short Weierstrass second coefficient.
b: constant(uint256) = 41_058_363_725_152_142_129_326_129_780_047_268_409_114_441_015_993_725_554_835_256_314_039_467_401_291


# @dev Generate point affine coordinates.
GX: constant(uint256) = 48_439_561_293_906_451_759_052_585_252_797_914_202_762_949_526_041_747_995_844_080_717_082_404_635_286
GY: constant(uint256) = 36_134_250_956_749_795_798_585_127_919_587_881_956_611_106_672_985_015_071_877_198_253_568_414_405_109


# @dev Curve order (number of points).
n: constant(uint256) = 115_792_089_210_356_248_762_697_446_949_407_573_529_996_955_224_135_760_342_422_259_061_068_512_044_369


# @dev The "-2 mod p" constant is used to speed up inversion and
# doubling (avoid negation).
minus_2modp: constant(uint256) = 115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_949
# @dev The "-2 mod n" constant is used to speed up inversion.
minus_2modn: constant(uint256) = 115_792_089_210_356_248_762_697_446_949_407_573_529_996_955_224_135_760_342_422_259_061_068_512_044_367


@deploy
@payable
def __init__():
    """
    @dev To omit the opcodes for checking the `msg.value`
         in the creation-time EVM bytecode, the constructor
         is declared as `payable`.
    """
    pass


@internal
@view
def _verify_sig(hash: bytes32, r: uint256, s: uint256, x: uint256, y: uint256) -> bool:
    """
    @dev Verifies the signature of a message digest `hash`
         based on the secp256r1 signature parameters `r` and
         `s`, and the public key coordinates `x` and `y`.
    @param hash The 32-byte message digest that was signed.
    @param r The secp256r1 32-byte signature parameter `r`.
    @param s The secp256r1 32-byte signature parameter `s`.
    @param x The 32-byte public key coordinate `x`.
    @param y The 32-byte public key coordinate `y`.
    @return bool The verification whether the signature is
            authentic or not.
    """
    # Checks if `r` and `s` are in the scalar field.
    if ((r == empty(uint256)) or (r >= n) or (s == empty(uint256)) or (s >= n)):
        return False

    if (not self._ec_aff_is_valid_pubkey(x, y)):
        return False

    s_inv: uint256 = self._n_mod_inv(s)

    # "(h * s^-1)" in scalar field.
    scalar_u: uint256 = uint256_mulmod(convert(hash, uint256), s_inv, n)
    # "(r * s^-1)" in scalar field.
    scalar_v: uint256 = uint256_mulmod(r, s_inv, n)

    r_x: uint256 = self._ec_zz_mulmuladd(x, y, scalar_u, scalar_v)
    return r_x % n == r


@internal
@pure
def _ec_aff_is_valid_pubkey(x: uint256, y: uint256) -> bool:
    """
    @dev Checks if a point in affine coordinates is on
         the curve. Rejects `0` point at infinity.
    @param x The 32-byte public key coordinate `x`.
    @param y The 32-byte public key coordinate `y`.
    @return bool The verification whether the point is
            on the curve or not.
    """
    if (x >= p or y >= p or (x == empty(uint256) and y == empty(uint256))):
        return False

    return self._ec_aff_satisfies_curve_eqn(x, y)


@internal
@pure
def _ec_aff_satisfies_curve_eqn(x: uint256, y: uint256) -> bool:
    """
    @dev Checks if a point in affine coordinates satisfies
         the curve equation.
    @param x The 32-byte public key coordinate `x`.
    @param y The 32-byte public key coordinate `y`.
    @return bool The verification whether the point satisfies
            the curve equation or not.
    """
    # y^2.
    lhs: uint256 = uint256_mulmod(y, y, p)
    # x^3 + a*x + b.
    rhs: uint256 = uint256_addmod(uint256_addmod(uint256_mulmod(uint256_mulmod(x, x, p), x, p), uint256_mulmod(a, x, p), p), b, p)
    return lhs == rhs


@internal
@view
def _ec_zz_mulmuladd(QX: uint256, QY: uint256, scalar_u: uint256, scalar_v: uint256) -> uint256:
    """
    @dev Computes "uG + vQ" using Strauss-Shamir's trick.
         Strauss-Shamir is described well here:
         https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method/50994362#50994362.
    @param Q
    """
    zz: uint256 = 1
    zzz: uint256 = 1
    X: uint256 = empty(uint256)
    Y: uint256 = empty(uint256)
    HX: uint256 = empty(uint256)
    HY: uint256 = empty(uint256)

    if (scalar_u == empty(uint256) and scalar_v == empty(uint256)):
        return empty(uint256)

    # "H = g + Q".
    (HX, HY) = self._ec_aff_add(GX, GY, QX, QY)

    index: int256 = 255
    bitpair: uint256 = empty(uint256)

    # Find the first bit index that is active in either `scalar_u` or `scalar_v`.
    for _: uint256 in range(255):
        bitpair = self._compute_bitpair(convert(index, uint256), scalar_u, scalar_v)
        # The following line cannot negatively overflow because we have limited the
        # for-loop by the constant value 255. The theoretically maximum achievable
        # value is therefore `-1`.
        index = unsafe_sub(index, 1)
        if (bitpair != empty(uint256)):
            break

    if (bitpair == 1):
        X = GX
        Y = GY
    elif (bitpair == 2):
        X = QX
        Y = QY
    elif (bitpair == 3):
        X = HX
        Y = HY

    TX: uint256 = empty(uint256)
    TY: uint256 = empty(uint256)

    for _: uint256 in range(255):
        if (index < empty(int256)):
            break

        (X, Y, zz, zzz) = self._ec_zz_double_zz(X, Y, zz, zzz)
        bitpair = self._compute_bitpair(convert(index, uint256), scalar_u, scalar_v)
        # The following line cannot negatively overflow because we have limited the
        # for-loop by the constant value 255. The theoretically maximum achievable
        # value is therefore `-1`.
        index = unsafe_sub(index, 1)

        if (bitpair == empty(uint256)):
            continue
        elif (bitpair == 1):
            TX = GX
            TY = GY
        elif (bitpair == 2):
            TX = QX
            TY = QY
        else:
            TX = HX
            TY = HY

        (X, Y, zz, zzz) = self._ec_zz_dadd_affine(X, Y, zz, zzz, TX, TY)

    # If `zz = 0`, `zzInv = 0`.
    zz_inv: uint256 = self._p_mod_inv(zz)
    # X/zz.
    return uint256_mulmod(X, zz_inv, p)


@internal
@pure
def _compute_bitpair(index: uint256, scalar_u: uint256, scalar_v: uint256) -> uint256:
    """
    @dev Compute the bits at `index` of `u` and `v` and return them as 2 bit
         concatenation. The bit at index 0 is on if the `index`th bit of `scalar_u`
         is on and the bit at index 1 is on if the `index`th bit of `scalar_v` is on.
         Examples:
            - compute_bitpair(0, 1, 1) == 3,
            - compute_bitpair(0, 1, 0) == 1,
            - compute_bitpair(0, 0, 1) == 2.
    """
    return (((scalar_v >> index) & 1) << 1) + ((scalar_u >> index) & 1)


@internal
@view
def _ec_aff_add(x1: uint256, y1: uint256, x2: uint256, y2: uint256) -> (uint256, uint256):
    """
    @dev Add two elliptic curve points in affine coordinates. Assumes that the points
         are on the elliptic curve.
    """
    zz1: uint256 = empty(uint256)
    zzz1: uint256 = empty(uint256)

    if (self._ec_aff_is_inf(x1, y1)):
        return (x2, y2)

    if (self._ec_aff_is_inf(x2, y2)):
        return (x1, y1)

    (x1, y1, zz1, zzz1) = self._ec_zz_dadd_affine(x1, y1, 1, 1, x2, y2)
    return self._ec_zz_set_aff(x1, y1, zz1, zzz1)


@internal
@pure
def _ec_aff_is_inf(x: uint256, y: uint256) -> bool:
    """
    @dev Check if a point is the infinity point in affine representation. Assumes that the
         point is on the elliptic curve or is the point at infinity.
    """
    return (x == empty(uint256) and y == empty(uint256))


@internal
@pure
def _ec_zz_is_inf(zz: uint256, zzz: uint256) -> bool:
    """
    @dev Check if a point is the infinity point in ZZ representation. Assumes point is on the
         elliptic curve or is the point at infinity.
    """
    return (zz == empty(uint256) and zzz == empty(uint256))


@internal
@view
def _ec_zz_dadd_affine(x1: uint256, y1: uint256, zz1: uint256, zzz1: uint256, x2: uint256, y2: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @dev Add a ZZ point to an affine point and return as ZZ representation. Uses "madd-2008-s" and
         "mdbl-2008-s" internally:
         https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-madd-2008-s. Matches:
         https://github.com/supranational/blst/blob/9c87d4a09d6648e933c818118a4418349804ce7f/src/ec_ops.h#L705
         closely. Handles points at infinity gracefully.
    """
    x3: uint256 = empty(uint256)
    y3: uint256 = empty(uint256)
    zz3: uint256 = empty(uint256)
    zzz3: uint256 = empty(uint256)

    # `(X2, Y2)` is point at infinity.
    if (self._ec_aff_is_inf(x2, y2)):
        if (self._ec_zz_is_inf(zz1, zzz1)):
            return self._ec_zz_point_at_inf()
        return (x1, y1, zz1, zzz1)
    # `(X1, Y1)` is point at infinity.
    elif (self._ec_zz_is_inf(zz1, zzz1)):
        return (x2, y2, 1, 1)

    # R = S2 - y1 = y2*zzz1 - y1.
    comp_r: uint256 = uint256_addmod(uint256_mulmod(y2, zzz1, p), p - y1, p)
    # P = U2 - x1 = x2*zz1 - x1.
    comp_p: uint256 = uint256_addmod(uint256_mulmod(x2, zz1, p), p - x1, p)

    # X1 != X2.
    if (comp_p != empty(uint256)):
        # PP = P^2.
        comp_pp: uint256 = uint256_mulmod(comp_p, comp_p, p)
        # PPP = P*PP.
        comp_ppp: uint256 = uint256_mulmod(comp_pp, comp_p, p)
        # ZZ3 = ZZ1*PP.
        zz3 = uint256_mulmod(zz1, comp_pp, p)
        # ZZZ3 = ZZZ1*PPP.
        zzz3 = uint256_mulmod(zzz1, comp_ppp, p)
        # Q = X1*PP.
        comp_q: uint256 = uint256_mulmod(x1, comp_pp, p)
        # R^2 - PPP - 2*Q
        x3 = uint256_addmod(uint256_addmod(uint256_mulmod(comp_r, comp_r, p), p - comp_ppp, p), uint256_mulmod(minus_2modp, comp_q, p), p)
        # Y3 = R*(Q-x3) - y1*PPP.
        return(x3, uint256_addmod(uint256_mulmod(uint256_addmod(comp_q, p - x3, p), comp_r, p), uint256_mulmod(p - y1, comp_ppp, p), p), zz3, zzz3)
    # X1 == X2 and Y1 == Y2.
    elif (comp_r == empty(uint256)):
        return self._ec_zz_double_affine(x2, y2)

    # X1 == X2 and Y1 == -Y2.
    return self._ec_zz_point_at_inf()


@internal
@pure
def _ec_zz_double_zz(x1: uint256, y1: uint256, zz1: uint256, zzz1: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @dev Double a ZZ point. Uses: http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-dbl-2008-s-1.
         Handles point at infinity gracefully.
    """
    if (self._ec_zz_is_inf(zz1, zzz1)):
        return self._ec_zz_point_at_inf()

    # U = 2*Y1.
    comp_u: uint256 = uint256_mulmod(2, y1, p)
    # V = U^2.
    comp_v: uint256 = uint256_mulmod(comp_u, comp_u, p)
    # W = U*V.
    comp_w: uint256 = uint256_mulmod(comp_u, comp_v, p)
    # S = X1*V.
    comp_s: uint256 = uint256_mulmod(x1, comp_v, p)
    # M = 3*(X1)^2 + a*(zz1)^2.
    comp_m: uint256 = uint256_addmod(uint256_mulmod(3, uint256_mulmod(x1, x1, p), p), uint256_mulmod(a, uint256_mulmod(zz1, zz1, p), p), p)

    # M^2 + (-2)*S.
    x3: uint256 = uint256_addmod(uint256_mulmod(comp_m, comp_m, p), uint256_mulmod(minus_2modp, comp_s, p), p)
    # Y3 = M*(S+(-X3)) + (-W)*Y1, ZZ3 = V*ZZ1, ZZZ3 = W*ZZZ1.
    return (x3, uint256_addmod(uint256_mulmod(comp_m, uint256_addmod(comp_s, p - x3, p), p), uint256_mulmod(p - comp_w, y1, p), p), uint256_mulmod(comp_v, zz1, p), uint256_mulmod(comp_w, zzz1, p))


@internal
@view
def _ec_zz_double_affine(x1: uint256, y1: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @dev Double an affine point and return as a ZZ point. Uses: http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-mdbl-2008-s-1.
         Handles point at infinity gracefully.
    """
    if (self._ec_aff_is_inf(x1, y1)):
        return self._ec_zz_point_at_inf()

    # U = 2*Y1.
    comp_u: uint256 = uint256_mulmod(2, y1, p)
    # V = U^2 = zz3.
    zz3: uint256 = uint256_mulmod(comp_u, comp_u, p)
    # W = U*V = zzz3.
    zzz3: uint256 = uint256_mulmod(comp_u, zz3, p)
    # S = X1*V.
    comp_s: uint256 = uint256_mulmod(x1, zz3, p)
    # M = 3*(X1)^2 + a.
    comp_m: uint256 = uint256_addmod(uint256_mulmod(3, uint256_mulmod(x1, x1, p), p), a, p)

    # M^2 + (-2)*S.
    x3: uint256 = uint256_addmod(uint256_mulmod(comp_m, comp_m, p), uint256_mulmod(minus_2modp, comp_s, p), p)
    # Y3 = M*(S+(-X3)) + (-W)*Y1.
    return (x3, uint256_addmod(uint256_mulmod(comp_m, uint256_addmod(comp_s, p - x3, p), p), uint256_mulmod(p - zzz3, y1, p), p), zz3, zzz3)


@internal
@view
def _ec_zz_set_aff(x: uint256, y: uint256, zz: uint256, zzz: uint256) -> (uint256, uint256):
    """
    @dev Convert from ZZ rep to affine representation. Assumes "(zz)^(3/2) == zzz (i.e. zz == z^2 and zzz == z^3)".
         See https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html.
    """
    x1: uint256 = empty(uint256)
    y1: uint256 = empty(uint256)
    if (self._ec_zz_is_inf(zz, zzz)):
        return self._ec_affine_point_at_inf()

    # 1 / zzz.
    zzz_inv: uint256 = self._p_mod_inv(zzz)
    # 1 / z.
    z_inv: uint256 = uint256_mulmod(zz, zzz_inv, p)
    # 1 / zz.
    zz_inv: uint256 = uint256_mulmod(z_inv, z_inv, p)

    # X1 = X / zz, y = Y / zzz.
    return (uint256_mulmod(x, zz_inv, p), uint256_mulmod(y, zzz_inv, p))


@internal
@pure
def _ec_zz_point_at_inf() -> (uint256, uint256, uint256, uint256):
    """
    @dev Point at infinity in ZZ representation.
    """
    return (empty(uint256), empty(uint256), empty(uint256), empty(uint256))


@internal
@pure
def _ec_affine_point_at_inf() -> (uint256, uint256):
    """
    @dev Point at infinity in affine representation.
    """
    return (empty(uint256), empty(uint256))


@internal
@view
def _n_mod_inv(u: uint256) -> uint256:
    """
    @dev "u^-1 mod n".
    """
    return self._mod_inv(u, n, minus_2modn)


@internal
@view
def _p_mod_inv(u: uint256) -> uint256:
    """
    @dev "u"^-1 mod p".
    """
    return self._mod_inv(u, p, minus_2modp)


@internal
@view
def _mod_inv(u: uint256, f: uint256, minus_2modf: uint256) -> uint256:
    """
    @dev "u^-1 mod f = u^(phi(f) - 1) mod f = u^(f-2) mod f" for prime f by Fermat's
         little theorem, compute "u^(f-2) mod f" using the `modexp` precompile. Assumes
         "f != 0". If `u` is 0, then "u^-1 mod f" is undefined mathematically, but this
         function returns 0.
    """
    c: uint256 = 32
    modexp: address = 0x0000000000000000000000000000000000000005
    return_data: Bytes[32] = b""
    success: bool = empty(bool)
    success, return_data = raw_call(modexp, _abi_encode(c, c, c, u, minus_2modf, f), max_outsize=32, is_static_call=True, revert_on_failure=False)
    # Since the `modexp` precompile cannot revert, we do
    # not assert a successful return.
    return _abi_decode(return_data, (uint256))
