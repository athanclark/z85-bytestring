{-# LANGUAGE
    OverloadedStrings
  #-}

import qualified Data.ByteString.Z85 as Z85
import Data.ByteString.Z85.Internal (encodeWord, decodeWord, printZ85Chunk)
import Data.Attoparsec.ByteString.Z85 (z85Encoded, anyWord32beEncoded)
import Data.Attoparsec.Text.Z85 (z85Decoded, anyZ85ChunkDecoded)

import Test.Tasty (testGroup, defaultMain)
import Test.Tasty.QuickCheck (testProperty)
import Test.Tasty.HUnit (testCase, (@=?))
import Test.QuickCheck (Property, (===))
import Test.QuickCheck.Instances ()

import Data.Word (Word32)
import Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import Data.ByteString.Lazy (toStrict)
import qualified Data.ByteString.Lazy as LBS
import Data.ByteString.Builder (word8, word32BE, toLazyByteString)
import qualified Data.Attoparsec.ByteString as AB
import qualified Data.Attoparsec.Text as AT




main :: IO ()
main = defaultMain $ testGroup "All Tests"
  [ testGroup "Unit Tests"
    [ testCase "\"HelloWorld\" == 0x86,0x4F,0xD2,0x6F,0xB5,0x59,0xF7,0x5B" $
      let bs = toStrict $ toLazyByteString $ foldMap word8 [0x86,0x4F,0xD2,0x6F,0xB5,0x59,0xF7,0x5B]
      in  AB.parseOnly z85Encoded bs @=? Right "HelloWorld"
    ]
  , testGroup "Property Tests"
    [ testProperty "decode / encode word iso" decodeWordIso
    , testProperty "decode / encode word iso over attoparsec" decodeWordIso'
    , testProperty "decode / encode sentence iso over attoparsec" encodeSentenceIsoA
    , testProperty "decode / encode sentence iso" encodeSentenceIso
    , testProperty "decode / encode sentence iso, residual failure" encodeSentenceIso'
    ]
  ]




decodeWordIso :: Word32 -> Property
decodeWordIso w = w === decodeWord (encodeWord w)



decodeWordIso' :: Word32 -> Property
decodeWordIso' w =
  let bs = toStrict (toLazyByteString (word32BE w))
  in  fmap (AT.parseOnly anyZ85ChunkDecoded . printZ85Chunk) (AB.parseOnly anyWord32beEncoded bs) === Right (Right w)



encodeSentenceIsoA :: ByteString -> Property
encodeSentenceIsoA x' =
  let xMod = BS.length x' `mod` 4
      x = if xMod /= 0
            then BS.drop xMod x'
            else x'
  in  fmap (AT.parseOnly z85Decoded) (AB.parseOnly z85Encoded x) === Right (Right x)


encodeSentenceIso :: LBS.ByteString -> Property
encodeSentenceIso x' =
  let xMod = LBS.length x' `mod` 4
      x = if xMod /= 0
            then LBS.drop xMod x'
            else x'
  in  fmap Z85.decode (Z85.encode x) === Right (Right x)


encodeSentenceIso' :: LBS.ByteString -> Property
encodeSentenceIso' x' =
  let xMod = LBS.length x' `mod` 4
      x = if xMod /= 0
            then LBS.drop xMod x'
            else x'
  in  fmap Z85.decode' (Z85.encode' x) === Right (Right x)
