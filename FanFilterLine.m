function [ filter] = FanFilterLine( N,a,type,cutoff)
%UNTITLED5 �� �Լ��� ��� ���� ��ġ
%   �ڼ��� ���� ��ġ
g=zeros(N,1);
x=-floor((N-1)/2):floor((N-1)/2);
g(x==0)=1/(8*a^2);
% g(x==0)=1/4;
odds= find(mod(x,2)==1);
g(odds)=-1./(2*pi^2*a^2*x(odds).^2);
% g(odds)=-1./(pi^2*x(odds).^2);
g=g(1:end-1);
filter=abs(fftshift(fft(g)));
w=2*pi*x(1:end-1)./(2*(N-1));
w=w';
switch lower(type)
    case 'ram-lak'
        %Do nothing
    case 'shepp-logan'
        filter=filter.*sin(w./(2*cutoff))./(w./(2*cutoff));
    case 'cosine'
        filter=filter.*cos(w./(2*cutoff));
    case 'hamming'
        filter=filter.*(0.54+0.46*cos(w./cutoff));
    case 'hann'
        filter=filter.*(0.5+0.5*cos(w./cutoff));
    otherwise
        error('Wrong filter selection')
end
filter(abs(w)>pi*cutoff)=0;

% for i=-floor((N-1)/2):floor((N-1)/2)
%     if(i==0)
%         g(c)=1/(8*a^2); %*sin(pi*(i*a)/(2*N))/(pi*(i*a)/(2*N));
%         c=c+1;
%     elseif(mod(abs(i),2)==0)
%         g(c)=0;
%         c=c+1;
%     else
%         g(c)=(-1/(2*pi^2*a^2*i^2)); %*sin(pi*(i*a)/(2*N))/(pi*(i*a)/(2*N));
%         c=c+1;
%     end
% end

end

