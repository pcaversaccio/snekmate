# pragma version ~=0.4.3
# pragma nonreentrancy off
"""
@title Elliptic Curve Digital Signature Algorithm (ECDSA) Secp256r1-Based Functions
@custom:contract-name p256
@license GNU Affero General Public License v3.0 only
@author pcaversaccio
@notice These functions can be used to verify signatures based on the
        non-Ethereum-native NIST P-256 elliptic curve (also known as
        secp256r1; see https://neuromancer.sk/std/secg/secp256r1). For
        more technical details, please refer to RIP-7212:
        https://github.com/ethereum/RIPs/blob/master/RIPS/rip-7212.md.
        The implementation is inspired by dcposch's and nalinbhardwaj's
        implementation here:
        https://github.com/daimo-eth/p256-verifier/blob/master/src/P256Verifier.sol.
@custom:security When using these functions, ensure that the underlying
                 chain supports the `MODEXP` precompiled contract at the
                 address `0x0000000000000000000000000000000000000005`,
                 as defined in EIP-198 (https://eips.ethereum.org/EIPS/eip-198)
                 and introduced in the Byzantium hard fork. Otherwise,
                 these functions will revert due to the absence of the
                 required precompiled contract. For example, ZKsync Era
                 does not currently support this precompiled contract:
                 https://docs.zksync.io/zksync-protocol/differences/pre-compiles.
"""


# @dev The `modexp` precompile address.
_MODEXP: constant(address) = 0x0000000000000000000000000000000000000005
# @dev The byte size length of `B` (base), `E` (exponent), and `M`
# (modulus) in the `modexp` precompile.
_C: constant(uint256) = 32


# @notice All of the constant values defined subsequently are
# parameters for the elliptical curve secp256r1 (see the standard
# curve database: https://neuromancer.sk/std/secg/secp256r1).


# @dev The secp256r1 curve order (number of points).
_N: constant(uint256) = (
    115_792_089_210_356_248_762_697_446_949_407_573_529_996_955_224_135_760_342_422_259_061_068_512_044_369
)


# @dev The malleability threshold used as part of the ECDSA
# verification function.
_MALLEABILITY_THRESHOLD: constant(uint256) = (
    57_896_044_605_178_124_381_348_723_474_703_786_764_998_477_612_067_880_171_211_129_530_534_256_022_184
)


# @dev The secp256r1 curve prime field modulus.
_P: constant(uint256) = (
    115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_951
)


# @dev The short Weierstrass first coefficient.
# @notice The assumption "_A == -3 (mod _P)" is used throughout
# the codebase.
_A: constant(uint256) = (
    115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_948
)
# @dev The short Weierstrass second coefficient.
_B: constant(uint256) = (
    41_058_363_725_152_142_129_326_129_780_047_268_409_114_441_015_993_725_554_835_256_314_039_467_401_291
)


# @dev The base generator point for "(qx, qy)".
_GX: constant(uint256) = (
    48_439_561_293_906_451_759_052_585_252_797_914_202_762_949_526_041_747_995_844_080_717_082_404_635_286
)
_GY: constant(uint256) = (
    36_134_250_956_749_795_798_585_127_919_587_881_956_611_106_672_985_015_071_877_198_253_568_414_405_109
)


# @dev The "-2 mod _P" constant is used to speed up inversion
# and doubling (avoid negation).
_MINUS_2MODP: constant(uint256) = (
    115_792_089_210_356_248_762_697_446_949_407_573_530_086_143_415_290_314_195_533_631_308_867_097_853_949
)
# @dev The "-2 mod _N" constant is used to speed up inversion.
_MINUS_2MODN: constant(uint256) = (
    115_792_089_210_356_248_762_697_446_949_407_573_529_996_955_224_135_760_342_422_259_061_068_512_044_367
)


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
def _verify_sig(hash: bytes32, r: uint256, s: uint256, qx: uint256, qy: uint256) -> bool:
    """
    @dev Verifies the signature of a message digest `hash`
         based on the secp256r1 signature parameters `r` and
         `s`, and the public key coordinates `qx` and `qy`.
    @param hash The 32-byte message digest that was signed.
    @param r The secp256r1 32-byte signature parameter `r`.
    @param s The secp256r1 32-byte signature parameter `s`.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return bool The verification whether the signature is
            authentic or not.
    """
    assert s <= _MALLEABILITY_THRESHOLD, "p256: invalid signature `s` value"

    # Check if `r` and `s` are in the scalar field.
    if r == empty(uint256) or r >= _N or s == empty(uint256) or s >= _N:
        return False

    if not self._ec_aff_is_valid_pubkey(qx, qy):
        return False

    s_inv: uint256 = self._n_mod_inv(s)

    # "(hash * s**(-1))" in scalar field.
    scalar_u: uint256 = uint256_mulmod(convert(hash, uint256), s_inv, _N)
    # "(r * s**(-1))" in scalar field.
    scalar_v: uint256 = uint256_mulmod(r, s_inv, _N)

    r_x: uint256 = self._ec_zz_mulmuladd(qx, qy, scalar_u, scalar_v)
    return r_x % _N == r


@internal
@pure
def _ec_aff_is_valid_pubkey(qx: uint256, qy: uint256) -> bool:
    """
    @dev Checks if a point in affine coordinates is on
         the curve. Rejects `0` point at infinity.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return bool The verification whether the point is
            on the curve or not.
    """
    if qx >= _P or qy >= _P or (qx == empty(uint256) and qy == empty(uint256)):
        return False

    return self._ec_aff_satisfies_curve_eqn(qx, qy)


@internal
@pure
def _ec_aff_satisfies_curve_eqn(qx: uint256, qy: uint256) -> bool:
    """
    @dev Checks if a point in affine coordinates satisfies
         the curve equation.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return bool The verification whether the point satisfies
            the curve equation or not.
    """
    # "qy**2".
    lhs: uint256 = uint256_mulmod(qy, qy, _P)
    # "qx**3 + _A*qx + _B".
    rhs: uint256 = uint256_addmod(
        uint256_addmod(uint256_mulmod(uint256_mulmod(qx, qx, _P), qx, _P), uint256_mulmod(_A, qx, _P), _P), _B, _P
    )
    return lhs == rhs


@internal
@view
def _ec_zz_mulmuladd(qx: uint256, qy: uint256, scalar_u: uint256, scalar_v: uint256) -> uint256:
    """
    @dev Computes "uG + vQ" using Strauss-Shamir's trick
         (G = basepoint, Q = public key). Strauss-Shamir
         is described well here:
         https://stackoverflow.com/a/50994362.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @param scalar_u The 32-byte field scalar `u`.
    @param scalar_v The 32-byte field scalar `v`.
    @return uint256 The 32-byte calculation result.
    """
    zz1: uint256 = 1
    zzz1: uint256 = 1
    qx1: uint256 = empty(uint256)
    qy1: uint256 = empty(uint256)
    hx: uint256 = empty(uint256)
    hy: uint256 = empty(uint256)

    if scalar_u == empty(uint256) and scalar_v == empty(uint256):
        return empty(uint256)

    # "H = G + Q".
    (hx, hy) = self._ec_aff_add(_GX, _GY, qx, qy)

    index: int256 = 255
    bitpair: uint256 = empty(uint256)

    # Find the first bit index that is active in either
    # `scalar_u` or `scalar_v`.
    for _: uint256 in range(255):
        bitpair = self._compute_bitpair(convert(index, uint256), scalar_u, scalar_v)
        # The following line cannot negatively overflow
        # because we have limited the for-loop by the
        # constant value `255`. The theoretically maximum
        # achievable value is therefore `-1`.
        index = unsafe_sub(index, 1)
        if bitpair != empty(uint256):
            break

    if bitpair == 1:
        qx1 = _GX
        qy1 = _GY
    elif bitpair == 2:
        qx1 = qx
        qy1 = qy
    elif bitpair == 3:
        qx1 = hx
        qy1 = hy

    qx2: uint256 = empty(uint256)
    qy2: uint256 = empty(uint256)

    for _: uint256 in range(255):
        if index < empty(int256):
            break

        (qx1, qy1, zz1, zzz1) = self._ec_zz_double_zz(qx1, qy1, zz1, zzz1)
        bitpair = self._compute_bitpair(convert(index, uint256), scalar_u, scalar_v)
        # The following line cannot negatively overflow
        # because we have limited the for-loop by the
        # constant value `255`. The theoretically maximum
        # achievable value is therefore `-1`.
        index = unsafe_sub(index, 1)

        if bitpair == empty(uint256):
            continue
        elif bitpair == 1:
            qx2 = _GX
            qy2 = _GY
        elif bitpair == 2:
            qx2 = qx
            qy2 = qy
        else:
            qx2 = hx
            qy2 = hy

        (qx1, qy1, zz1, zzz1) = self._ec_zz_dadd_affine(qx1, qy1, zz1, zzz1, qx2, qy2)

    # If `zz1 = 0` then `zz1_inv = 0`.
    zz1_inv: uint256 = self._p_mod_inv(zz1)
    # "qx1/zz1".
    return uint256_mulmod(qx1, zz1_inv, _P)


@internal
@pure
def _compute_bitpair(index: uint256, scalar_u: uint256, scalar_v: uint256) -> uint256:
    """
    @dev Computes the bits at `index` of `scalar_u` and
         `scalar_v` and returns them as 2 bit concatenation.
         The bit at index `0` is on if the `index`th bit
         of `scalar_u` is on and the bit at index `1` is
         on if the `index`th bit of `scalar_v` is on.
         Examples:
            - `compute_bitpair(0, 1, 1) == 3`,
            - `compute_bitpair(0, 1, 0) == 1`,
            - `compute_bitpair(0, 0, 1) == 2`.
    @param index The 32-byte index.
    @param scalar_u The 32-byte field scalar `u`.
    @param scalar_v The 32-byte field scalar `v`.
    @return uint256 The 32-byte calculation result.
    """
    return (((scalar_v >> index) & 1) << 1) | ((scalar_u >> index) & 1)


@internal
@view
def _ec_aff_add(qx1: uint256, qy1: uint256, qx2: uint256, qy2: uint256) -> (uint256, uint256):
    """
    @dev Adds two elliptic curve points in affine coordinates.
         Assumes that the points are on the elliptic curve.
    @param qx1 The first 32-byte public key coordinate `qx1`.
    @param qy1 The first 32-byte public key coordinate `qy1`.
    @param qx2 The second 32-byte public key coordinate `qx2`.
    @param qy2 The second 32-byte public key coordinate `qy2`.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    """
    zz1: uint256 = empty(uint256)
    zzz1: uint256 = empty(uint256)

    if self._ec_aff_is_inf(qx1, qy1):
        return (qx2, qy2)

    if self._ec_aff_is_inf(qx2, qy2):
        return (qx1, qy1)

    (qx1, qy1, zz1, zzz1) = self._ec_zz_dadd_affine(qx1, qy1, 1, 1, qx2, qy2)
    return self._ec_zz_set_aff(qx1, qy1, zz1, zzz1)


@internal
@pure
def _ec_aff_is_inf(qx: uint256, qy: uint256) -> bool:
    """
    @dev Checks if a point is the infinity point in affine
         representation. Assumes that the point is on the
         elliptic curve or is the point at infinity.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return bool The verification whether a point is
            the infinity point or not.
    """
    return ((qx == empty(uint256)) and (qy == empty(uint256)))


@internal
@pure
def _ec_zz_is_inf(zz: uint256, zzz: uint256) -> bool:
    """
    @dev Checks if a point is the infinity point in ZZ
         representation. Assumes point is on the
         elliptic curve or is the point at infinity.
    @param zz The 32-byte public key coordinate `qx` in ZZ
           representation.
    @param zzz The 32-byte public key coordinate `qy` in ZZ
           representation.
    @return bool The verification whether a point is
            the infinity point or not.
    """
    return ((zz == empty(uint256)) and (zzz == empty(uint256)))


@internal
@view
def _ec_zz_dadd_affine(
    qx1: uint256, qy1: uint256, zz1: uint256, zzz1: uint256, qx2: uint256, qy2: uint256
) -> (uint256, uint256, uint256, uint256):
    """
    @dev Adds a ZZ point to an affine point and returns as
         ZZ representation. Uses "madd-2008-s" and "mdbl-2008-s"
         internally:
         https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html#addition-madd-2008-s.
         It matches closely:
         https://github.com/supranational/blst/blob/704c7f6d5f99ebb6bda84f635122e449ee51aa48/src/ec_ops.h#L710.
         Handles points at infinity gracefully.
    @param qx1 The first 32-byte public key coordinate `qx1`.
    @param qy1 The first 32-byte public key coordinate `qy1`.
    @param zz1 The 32-byte public key coordinate `qx1` in ZZ
           representation.
    @param zzz1 The 32-byte public key coordinate `qy1` in ZZ
           representation.
    @param qx2 The second 32-byte public key coordinate `qx2`.
    @param qy2 The second 32-byte public key coordinate `qy2`.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    @return uint256 The computed 32-byte public key coordinate `qx`
            in ZZ representation.
    @return uint256 The computed 32-byte public key coordinate `qy`
            in ZZ representation.
    """
    qx3: uint256 = empty(uint256)
    qy3: uint256 = empty(uint256)
    zz3: uint256 = empty(uint256)
    zzz3: uint256 = empty(uint256)

    # `(qx2, qy2)` is point at infinity.
    if self._ec_aff_is_inf(qx2, qy2):
        if self._ec_zz_is_inf(zz1, zzz1):
            return self._ec_zz_point_at_inf()
        return (qx1, qy1, zz1, zzz1)
    # `(qx1, qy1)` is point at infinity.
    elif self._ec_zz_is_inf(zz1, zzz1):
        return (qx2, qy2, 1, 1)

    # "r = s2 - qy1 = qy2*zzz1 - qy1".
    comp_r: uint256 = uint256_addmod(uint256_mulmod(qy2, zzz1, _P), unsafe_sub(_P, qy1), _P)
    # "p = u2 - qx1 = qx2*zz1 - qx1".
    comp_p: uint256 = uint256_addmod(uint256_mulmod(qx2, zz1, _P), unsafe_sub(_P, qx1), _P)

    # "qx1 != qx2".
    if comp_p != empty(uint256):
        # "pp = p**2".
        comp_pp: uint256 = uint256_mulmod(comp_p, comp_p, _P)
        # "ppp = p*pp".
        comp_ppp: uint256 = uint256_mulmod(comp_pp, comp_p, _P)
        # "zz3 = zz1*pp".
        zz3 = uint256_mulmod(zz1, comp_pp, _P)
        # "zzz3 = zzz1*ppp".
        zzz3 = uint256_mulmod(zzz1, comp_ppp, _P)
        # "q = qx1*pp".
        comp_q: uint256 = uint256_mulmod(qx1, comp_pp, _P)
        # "r**2 - ppp - 2*q".
        qx3 = uint256_addmod(
            uint256_addmod(uint256_mulmod(comp_r, comp_r, _P), unsafe_sub(_P, comp_ppp), _P),
            uint256_mulmod(_MINUS_2MODP, comp_q, _P),
            _P,
        )
        # "qy3 = r*(q-qx3) - qy1*ppp".
        return (
            qx3,
            uint256_addmod(
                uint256_mulmod(uint256_addmod(comp_q, unsafe_sub(_P, qx3), _P), comp_r, _P),
                uint256_mulmod(unsafe_sub(_P, qy1), comp_ppp, _P),
                _P,
            ),
            zz3,
            zzz3,
        )
    # "qx1 == qx2 and qy1 == qy2".
    elif comp_r == empty(uint256):
        return self._ec_zz_double_affine(qx2, qy2)

    # "qx1 == qx2 and qy1 == -qy2".
    return self._ec_zz_point_at_inf()


@internal
@pure
def _ec_zz_double_zz(qx: uint256, qy: uint256, zz: uint256, zzz: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @dev Doubles a ZZ point. Uses: http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-dbl-2008-s-1.
         Handles points at infinity gracefully.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @param zz The 32-byte public key coordinate `qx` in ZZ
           representation.
    @param zzz The 32-byte public key coordinate `qy` in ZZ
           representation.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    @return uint256 The computed 32-byte public key coordinate `qx`
            in ZZ representation.
    @return uint256 The computed 32-byte public key coordinate `qy`
            in ZZ representation.
    """
    if self._ec_zz_is_inf(zz, zzz):
        return self._ec_zz_point_at_inf()

    # "u = 2*qy".
    comp_u: uint256 = uint256_mulmod(2, qy, _P)
    # "v = u**2".
    comp_v: uint256 = uint256_mulmod(comp_u, comp_u, _P)
    # "w = u*v".
    comp_w: uint256 = uint256_mulmod(comp_u, comp_v, _P)
    # "s = qx*v".
    comp_s: uint256 = uint256_mulmod(qx, comp_v, _P)
    # "m = 3*(qx)**2 + _A*(zz)**2".
    comp_m: uint256 = uint256_addmod(
        uint256_mulmod(3, uint256_mulmod(qx, qx, _P), _P), uint256_mulmod(_A, uint256_mulmod(zz, zz, _P), _P), _P
    )

    # "m**2 + (-2)*s".
    qx3: uint256 = uint256_addmod(uint256_mulmod(comp_m, comp_m, _P), uint256_mulmod(_MINUS_2MODP, comp_s, _P), _P)
    # "qy3 = m*(s+(-qx3)) + (-w)*qy, zz3 = v*zz, zzz3 = w*zzz".
    return (
        qx3,
        uint256_addmod(
            uint256_mulmod(comp_m, uint256_addmod(comp_s, unsafe_sub(_P, qx3), _P), _P),
            uint256_mulmod(unsafe_sub(_P, comp_w), qy, _P),
            _P,
        ),
        uint256_mulmod(comp_v, zz, _P),
        uint256_mulmod(comp_w, zzz, _P),
    )


@internal
@view
def _ec_zz_double_affine(qx: uint256, qy: uint256) -> (uint256, uint256, uint256, uint256):
    """
    @dev Doubles an affine point and returns as a ZZ point.
         Uses: http://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz.html#doubling-mdbl-2008-s-1.
         Handles point at infinity gracefully.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    @return uint256 The computed 32-byte public key coordinate `qx`
            in ZZ representation.
    @return uint256 The computed 32-byte public key coordinate `qy`
            in ZZ representation.
    """
    if self._ec_aff_is_inf(qx, qy):
        return self._ec_zz_point_at_inf()

    # "u = 2*qy".
    comp_u: uint256 = uint256_mulmod(2, qy, _P)
    # "v = u**2 = zz3".
    zz3: uint256 = uint256_mulmod(comp_u, comp_u, _P)
    # "w = u*v = zzz3".
    zzz3: uint256 = uint256_mulmod(comp_u, zz3, _P)
    # "s = qx*v".
    comp_s: uint256 = uint256_mulmod(qx, zz3, _P)
    # "m = 3*(qx)**2 + _A".
    comp_m: uint256 = uint256_addmod(uint256_mulmod(3, uint256_mulmod(qx, qx, _P), _P), _A, _P)

    # "m**2 + (-2)*s".
    qx3: uint256 = uint256_addmod(uint256_mulmod(comp_m, comp_m, _P), uint256_mulmod(_MINUS_2MODP, comp_s, _P), _P)
    # "qy3 = m*(s+(-qx3)) + (-w)*qy".
    return (
        qx3,
        uint256_addmod(
            uint256_mulmod(comp_m, uint256_addmod(comp_s, unsafe_sub(_P, qx3), _P), _P),
            uint256_mulmod(unsafe_sub(_P, zzz3), qy, _P),
            _P,
        ),
        zz3,
        zzz3,
    )


@internal
@view
def _ec_zz_set_aff(qx: uint256, qy: uint256, zz: uint256, zzz: uint256) -> (uint256, uint256):
    """
    @dev Converts from ZZ representation to affine representation.
         Assumes "(zz)**(3/2) == zzz (i.e. zz == z**2 and zzz == z**3)".
         See https://hyperelliptic.org/EFD/g1p/auto-shortw-xyzz-3.html.
    @param qx The 32-byte public key coordinate `qx`.
    @param qy The 32-byte public key coordinate `qy`.
    @param zz The 32-byte public key coordinate `qx` in ZZ
           representation.
    @param zzz The 32-byte public key coordinate `qy` in ZZ
           representation.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    """
    qx1: uint256 = empty(uint256)
    qy1: uint256 = empty(uint256)
    if self._ec_zz_is_inf(zz, zzz):
        return self._ec_affine_point_at_inf()

    # "1/zzz".
    zzz_inv: uint256 = self._p_mod_inv(zzz)
    # "1/z".
    z_inv: uint256 = uint256_mulmod(zz, zzz_inv, _P)
    # "1/zz".
    zz_inv: uint256 = uint256_mulmod(z_inv, z_inv, _P)

    # "qx1 = qx/zz, qy1 = qy/zzz."
    return (uint256_mulmod(qx, zz_inv, _P), uint256_mulmod(qy, zzz_inv, _P))


@internal
@pure
def _ec_zz_point_at_inf() -> (uint256, uint256, uint256, uint256):
    """
    @dev Computes the point at infinity in ZZ representation.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    @return uint256 zz The computed 32-byte public key coordinate `qx`
            in ZZ representation.
    @return uint256 zzz The computed 32-byte public key coordinate `qy`
            in ZZ representation.
    """
    return (empty(uint256), empty(uint256), empty(uint256), empty(uint256))


@internal
@pure
def _ec_affine_point_at_inf() -> (uint256, uint256):
    """
    @dev Computes the point at infinity in affine representation.
    @return uint256 The computed 32-byte public key coordinate `qx`.
    @return uint256 The computed 32-byte public key coordinate `qy`.
    """
    return (empty(uint256), empty(uint256))


@internal
@view
def _n_mod_inv(u: uint256) -> uint256:
    """
    @dev Computes "u**(-1) mod _N".
    @param u The 32-byte base for the `modexp` precompile.
    @return uint256 The 32-byte calculation result.
    """
    return self._mod_inv(u, _MINUS_2MODN, _N)


@internal
@view
def _p_mod_inv(u: uint256) -> uint256:
    """
    @dev Computes "u"**(-1) mod _P".
    @param u The 32-byte base for the `modexp` precompile.
    @return uint256 The 32-byte calculation result.
    """
    return self._mod_inv(u, _MINUS_2MODP, _P)


@internal
@view
def _mod_inv(u: uint256, minus_2modf: uint256, f: uint256) -> uint256:
    """
    @dev Computes "u**(-1) mod f = u**(phi(f) - 1) mod f = u**(f-2) mod f"
         for prime f by Fermat's little theorem, compute "u**(f-2) mod f"
         using the `modexp` precompile. Assumes "f != 0". If `u` is `0`,
         then "u**(-1) mod f" is undefined mathematically, but this function
         returns `0`.
    @param u The 32-byte base for the `modexp` precompile.
    @param minus_2modf The 32-byte exponent for the `modexp` precompile.
    @param f The 32-byte modulus for the `modexp` precompile.
    @return uint256 The 32-byte calculation result.
    """
    return_data: Bytes[32] = b""
    return_data = raw_call(_MODEXP, abi_encode(_C, _C, _C, u, minus_2modf, f), max_outsize=32, is_static_call=True)
    return abi_decode(return_data, (uint256))
