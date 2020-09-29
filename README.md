### JPEG200_open
This ia a simple jpeg2000 hardware encoder.
#### feature supported

*    Monochrome 
*    Wavelet transforms: 5/3 
*    Decomposition levels:  1~5
*    Layer: Only one layer
*    Tile:  128x128
*    Code Block: 64x64

#### Description
It only supports dwt53 and  does not have ratecontrol , actually it is a lossless encoder. 
For simplicity it uses Tile 128x128 and CodeBlock 64x64,  so there is only one codeblcok in a Band, 
and does not need external DDR memory to store intermediate coeff and stream. 

This code is just for function evaluation, no optimization techniques for speed and area applied.

For commercial version Jpeg2000 encoder IP contact me via the E-mail.
#### Author
LulinChen 
[lulinchen@aliyun.com](lulinchen@aliyun.com)