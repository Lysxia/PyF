{-# OPTIONS -Wno-type-defaults #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# LANGUAGE TemplateHaskell #-}

import Test.Hspec

import PyF
import SpecUtils

{-
   - Normal tests are done using the recommanded API: [fString|.....|]
   - Test with $(checkExample formatString result) are checked against the python reference implementation. Result is provided as documentation.
   - Test with $(checkExampleDiff formatString result) are not checked against the python reference implementation. This is known (and documented) differences.
   - Test with $(check formatString) are only tested against the python reference implementation.
-}

main :: IO ()
main = hspec spec

spec :: Spec
spec = do
  describe "simple with external variable" $ do
    let
      anInt = 123
      aFloat = 0.234
      aString = "hello"
    it "int" $ [fString|{anInt}|] `shouldBe` "123"
    it "float" $ [fString|{aFloat}|] `shouldBe` "0.234"
    it "string" $ [fString|{aString}|] `shouldBe` "hello"
  describe "only expression" $ do
    describe "default" $ do
      it "int" $(checkExample "{123}" "123")
      it "float" $(checkExample "{0.234}" "0.234")
      it "string" $(checkExample "{\"hello\"}" "hello")
      it "float precision" $(checkExample "{0.234:.1}" "0.2")
      it "string precision" $(checkExample "{\"hello\":.1}" "h")
      it "sign +" $(checkExample "{0.234:+}" "+0.234")
      it "sign space" $(checkExample "{0.234: }" " 0.234")
      it "sign neg" $(checkExample "{-123:+}" "-123")
    describe "binary" $ do
      it "simple" $(checkExample "{123:b}" "1111011")
      it "alt" $(checkExample "{123:#b}" "0b1111011")
      it "sign" $(checkExample "{123:+#b}" "+0b1111011")
    describe "character" $ do
      it "simple" $(checkExample "{123:c}" "{")
    describe "decimal" $ do
      it "simple" $(checkExample "{123:d}" "123")
      it "sign" $(checkExample "{123:+d}" "+123")
    describe "exponentiel" $ do
      it "simple > 1" $(checkExample "{234.0:e}" "2.340000e+02")
      it "precision > 1" $(checkExample "{234.0:.1e}" "2.3e+02")
      it "simple < 1" $(checkExample "{0.234:e}" "2.340000e-01")
      it "precision < 1 " $(checkExample "{0.234:.1e}" "2.3e-01")
    describe "exponentiel caps" $ do
      it "simple > 1" $(checkExample "{234.0:E}" "2.340000E+02")
      it "precision > 1" $(checkExample "{234.0:.1E}" "2.3E+02")
      it "simple < 1" $(checkExample "{0.234:E}" "2.340000E-01")
      it "precision < 1 " $(checkExample "{0.234:.1E}" "2.3E-01")
    describe "general" $ do
      it "simple small" $(checkExampleDiff "{123.02:g}" "123.020000")
      it "precision small" $(checkExampleDiff "{123.02:.1g}" "123.0")
      it "simple big" $(checkExampleDiff "{1234567890.23:g}" "1.234568e9")
      it "precision big" $(checkExampleDiff "{1234567890.23:.1g}" "1.2e9")
    describe "general caps" $ do
      it "simple small" $(checkExampleDiff "{123.02:G}" "123.020000")
      it "precision small" $(checkExampleDiff "{123.02:.1G}" "123.0")
      it "simple big" $(checkExampleDiff "{1234567890.23:G}" "1.234568E9")
      it "precision big" $(checkExampleDiff "{1234567890.23:.1G}" "1.2E9")
    describe "fixed" $ do
      it "simple" $(checkExample "{0.234:f}" "0.234000")
      it "precision" $(checkExample "{0.234:.1f}" "0.2")
    describe "fixed caps" $ do
      it "simple" $(checkExample "{0.234:F}" "0.234000")
      it "precision" $(checkExample "{0.234:.1F}" "0.2")
    describe "octal" $ do
      it "simple" $(checkExample "{123:o}" "173")
      it "alt" $(checkExample "{123:#o}" "0o173")
    describe "string" $ do
      it "string" $(checkExample "{\"hello\":s}" "hello")
      it "precision" $(checkExample "{\"hello\":.2s}" "he")
    describe "hex" $ do
      it "simple" $(checkExample "{123:x}" "7b")
      it "alt" $(checkExample "{123:#x}" "0x7b")
    describe "hex caps" $ do
      it "simple" $(checkExample "{123:X}" "7B")
      it "alt" $(checkExample "{123:#X}" "0X7B")
    describe "percent" $ do
      it "simple" $(checkExample "{0.234:%}" "23.400000%")
      it "precision" $(checkExample "{0.234:.2%}" "23.40%")
    describe "padding" $ do
      describe "default char" $ do
        it "left" $(checkExample "{\"hello\":<10}" "hello     ")
        it "right" $(checkExample "{\"hello\":>10}" "     hello")
        it "center" $(checkExample "{\"hello\":^10}" "  hello   ")
      describe "a char" $ do
        it "left" $(checkExample "{\"hello\":-<10}" "hello-----")
        it "right" $(checkExample "{\"hello\":->10}" "-----hello")
        it "center" $(checkExample "{\"hello\":-^10}" "--hello---")
      describe "inside" $ do
        it "inside" $(checkExample "{123:=+10}" "+      123")
        it "inside" $(checkExample "{123:=10}" "       123")
        it "inside" $(checkExample "{- 123:=10}" "-      123")
        it "inside" $(checkExample "{- 123:|= 10}" "-||||||123")
        it "inside" $(checkExample "{123:|= 10}" " ||||||123")
      describe "default padding" $ do
        it "floating" $(checkExample "{1:10f}" "  1.000000")
        it "integral" $(checkExample "{1:10d}" "         1")
        it "string" $(checkExample "{\"h\":10s}" "h         ")
        it "default" $(checkExample "{1:10}" "         1")
        it "default" $(checkExample "{1.0:10}" "       1.0")
        it "default" $(checkExample "{\"h\":10}" "h         ")
    describe "NaN" $ do
        let nan = 0.0 / 0
        it "nan" $(checkExample "{nan}" "nan")
        it "nan f" $(checkExample "{nan:f}" "nan")
        it "nan e" $(checkExample "{nan:e}" "nan")
        it "nan g" $(checkExample "{nan:g}" "nan")
        it "nan F" $(checkExample "{nan:F}" "NAN")
        it "nan G" $(checkExample "{nan:G}" "NAN")
        it "nan E" $(checkExample "{nan:E}" "NAN")
    describe "Infinite" $ do
        let inf = 1.0 / 0
        it "infinite" $(checkExample "{inf}" "inf")
        it "infinite f" $(checkExample "{inf:f}" "inf")
        it "infinite e" $(checkExample "{inf:e}" "inf")
        it "infinite g" $(checkExample "{inf:g}" "inf")
        it "infinite F" $(checkExample "{inf:F}" "INF")
        it "infinite G" $(checkExample "{inf:G}" "INF")
        it "infinite E" $(checkExample "{inf:E}" "INF")
    describe "Grouping" $ do
        it "groups int" $(checkExample "{123456789:,d}" "123,456,789")
        it "groups int with _" $(checkExample "{123456789:_d}" "123_456_789")
        it "groups float" $(checkExample "{123456789.234:,f}" "123,456,789.234000")
        it "groups bin" $(checkExample "{123456789:_b}" "111_0101_1011_1100_1101_0001_0101")
        it "groups hex" $(checkExample "{123456789:_x}" "75b_cd15")
        it "groups oct" $(checkExample "{123456789:_o}" "7_2674_6425")
    describe "negative zero" $ do
        it "f" $(checkExample "{-0.0:f}" "-0.000000")
        it "e" $(checkExample "{-0.0:e}" "-0.000000e+00")
        it "g" $(checkExampleDiff "{-0.0:g}" "-0.000000")
        it "F" $(checkExample "{-0.0:F}" "-0.000000")
        it "G" $(checkExampleDiff "{-0.0:G}" "-0.000000")
        it "E" $(checkExample "{-0.0:E}" "-0.000000E+00")
    describe "0" $ do
        it "works" $(checkExample "{123:010}" "0000000123")
        it "works with sign" $(checkExample "{-123:010}" "-000000123")
        it "accept mode override" $(checkExample "{-123:<010}" "-123000000")
        it "accept mode and char override" $(checkExample "{-123:.<010}" "-123......")
  describe "complex" $ do
    it "works with many things at once" $
      let
        name = "Guillaume"
        age = 31
        euroToFrancs = 6.55957
      in
        [fString|hello {name} you are {age} years old and the conversion rate of euro is {euroToFrancs:.2}|] `shouldBe` ("hello Guillaume you are 31 years old and the conversion rate of euro is 6.56")


  describe "error reporting" $ do
    pure () -- TODO: find a way to test error reporting

  describe "sub expressions" $ do
    it "works" $ do
      [fString|2pi = {2 * pi:.2}|] `shouldBe` "2pi = 6.28"

  describe "escape strings" $ do
    it "works" $ do
      [fString|hello \n\b|] `shouldBe` "hello \n\b"
