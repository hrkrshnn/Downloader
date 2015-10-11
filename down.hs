{-# LANGUAGE OverloadedStrings #-}
import System.IO
import System.Environment
import System.Process
import Control.Monad
import qualified Data.ByteString as B

splitSize = 128 * 1024 * 1024 -- 128 Mega Bytes

download :: String -> IO ()
download url = do
  system $ "curl -sI " ++ url ++
             " | awk '/Content-Length/ { print $2 }' > /tmp/hacurl"
  fileSize <- fmap (read) $ readFile $ "/tmp/hacurl" :: IO Int
  putStrLn $ show fileSize
  let splits = ((fromIntegral fileSize) / (fromIntegral splitSize))
      rs = ceiling splits
      xss = map (\x -> download' url x fileSize)  [1..rs]
  putStrLn $ "Number of splits: " ++ (show rs)
  foldr (>>) (return ()) xss
  combine rs

download' :: String -> Int -> Int -> IO ()
download' url n tot = do
  system $ "curl -o \"file." ++ (show n) ++
             "\" --range " ++ start ++  "-" ++ end ++ " " ++ url
  return ()
    where
      start = show $ (n - 1) * splitSize
      end = let size = (n * splitSize - 1)
            in show $ if size > tot then tot else size

combine :: Int -> IO ()
combine n = do
  let xs = map (\x -> aux x) [1..n]
  all <- foldr (aux') (return "") xs
  B.writeFile "file" all  
      where aux x = B.readFile $ "file." ++ (show x)
            aux' :: IO B.ByteString -> IO B.ByteString -> IO B.ByteString
            aux' s1 s2 = liftM2 B.append s1 s2

main = do
  ar <- fmap head $ getArgs
  putStrLn $ ar
  download ar

