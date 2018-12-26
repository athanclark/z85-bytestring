module Data.Attoparsec.ByteString.Z85 where

import Data.ByteString.Z85.Internal (Z85Char (..), Z85Chunk, z85Chars, encodeWord)
import Data.Attoparsec.ByteString (Parser)
import Data.Attoparsec.Binary (anyWord32le)
import Data.Word (Word32)



anyWord32leEncoded :: Parser Z85Chunk
anyWord32leEncoded = encodeWord <$> anyWord32le


z85Encoded :: Parser Text
z85Encoded = fold <$> many (printZ85Chunk <$> anyWord32leEncoded)